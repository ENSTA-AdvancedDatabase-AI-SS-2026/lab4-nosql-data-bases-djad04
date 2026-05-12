"""
TP5 - Benchmark Comparatif NoSQL
Mesurer les performances de Redis, MongoDB, Cassandra, Neo4j
"""
import time
import statistics
import json
from typing import Callable, List, Tuple
import redis
from pymongo import MongoClient
from cassandra.cluster import Cluster
from neo4j import GraphDatabase

# ─── Utilitaires de mesure ────────────────────────────────────────────────────

def measure_latency(fn: Callable, iterations: int = 1000) -> dict:
    """
    Exécuter fn iterations fois et retourner les statistiques
    """
    latencies = []
    for _ in range(iterations):
        start = time.perf_counter()
        fn()
        latencies.append((time.perf_counter() - start) * 1000)  # en ms
    
    latencies.sort()
    return {
        "mean_ms": statistics.mean(latencies),
        "p50_ms": latencies[int(0.50 * len(latencies))],
        "p95_ms": latencies[int(0.95 * len(latencies))],
        "p99_ms": latencies[int(0.99 * len(latencies))],
        "max_ms": max(latencies),
        "throughput_rps": 1000 / statistics.mean(latencies)
    }


def print_results(name: str, results: dict):
    print(f"\n{'='*50}")
    print(f" {name}")
    print(f"{'='*50}")
    for k, v in results.items():
        print(f"  {k:20s}: {v:.2f}")


# ─── Ex1 : Benchmark Écriture ─────────────────────────────────────────────────

def benchmark_write_redis(n: int = 100_000):
    r = redis.Redis(host='localhost', port=6379, decode_responses=True)
    r.flushdb()
    start = time.perf_counter()
    pipe = r.pipeline()
    for i in range(n):
        pipe.set(f"key:{i}", f"value_{i}")
        if i % 10000 == 0 and i > 0:
            pipe.execute()
    pipe.execute()
    elapsed = time.perf_counter() - start
    print(f"Redis Write: {elapsed:.2f}s, Throughput: {n/elapsed:.0f} ops/s")


def benchmark_write_mongodb(n: int = 100_000):
    client = MongoClient("mongodb://admin:admin123@localhost:27017/")
    db = client["benchmark"]
    db.test_collection.drop()
    start = time.perf_counter()
    batch = []
    for i in range(n):
        batch.append({"key": f"key:{i}", "value": f"value_{i}"})
        if len(batch) >= 10000:
            db.test_collection.insert_many(batch)
            batch = []
    if batch:
        db.test_collection.insert_many(batch)
    elapsed = time.perf_counter() - start
    print(f"MongoDB Write: {elapsed:.2f}s, Throughput: {n/elapsed:.0f} ops/s")


def benchmark_write_cassandra(n: int = 100_000):
    try:
        cluster = Cluster(['localhost'])
        session = cluster.connect()
        session.execute("CREATE KEYSPACE IF NOT EXISTS benchmark WITH replication = {'class':'SimpleStrategy', 'replication_factor':1}")
        session.set_keyspace('benchmark')
        session.execute("CREATE TABLE IF NOT EXISTS test_table (key text PRIMARY KEY, value text)")
        session.execute("TRUNCATE test_table")
        
        prepared = session.prepare("INSERT INTO test_table (key, value) VALUES (?, ?)")
        start = time.perf_counter()
        
        from cassandra.query import BatchStatement, BatchType
        batch = BatchStatement(batch_type=BatchType.UNLOGGED)
        count = 0
        for i in range(n):
            batch.add(prepared, (f"key:{i}", f"value_{i}"))
            count += 1
            if count >= 100:
                session.execute(batch)
                batch.clear()
                count = 0
        if count > 0:
            session.execute(batch)
        elapsed = time.perf_counter() - start
        print(f"Cassandra Write: {elapsed:.2f}s, Throughput: {n/elapsed:.0f} ops/s")
    except Exception as e:
        print("Cassandra Write Failed (Maybe not running):", e)
        
def benchmark_write_neo4j(n: int = 100_000):
    try:
        driver = GraphDatabase.driver("bolt://localhost:7687", auth=("neo4j", "password123"))
        with driver.session() as session:
            session.run("MATCH (n:BenchNode) DETACH DELETE n")
            start = time.perf_counter()
            batch = []
            for i in range(n):
                batch.append({"key": f"key:{i}", "value": f"value_{i}"})
                if len(batch) >= 10000:
                    session.run("UNWIND $batch AS row MERGE (n:BenchNode {key: row.key}) SET n.value = row.value", batch=batch)
                    batch = []
            if batch:
                session.run("UNWIND $batch AS row MERGE (n:BenchNode {key: row.key}) SET n.value = row.value", batch=batch)
            elapsed = time.perf_counter() - start
            print(f"Neo4j Write: {elapsed:.2f}s, Throughput: {n/elapsed:.0f} ops/s")
        driver.close()
    except Exception as e:
        print("Neo4j Write Failed (Maybe not running):", e)


# ─── Ex2 : Benchmark Lecture ─────────────────────────────────────────────────

def benchmark_read_redis():
    r = redis.Redis(host='localhost', port=6379, decode_responses=True)
    def point_lookup(): r.get("key:500")
    res = measure_latency(point_lookup, 1000)
    print_results("Redis Read (Point Lookup)", res)


def benchmark_read_mongodb():
    client = MongoClient("mongodb://admin:admin123@localhost:27017/")
    db = client["benchmark"]
    def point_lookup(): db.test_collection.find_one({"key": "key:500"})
    res = measure_latency(point_lookup, 1000)
    print_results("MongoDB Read (Point Lookup)", res)


# ─── Ex3 : Charge concurrente ─────────────────────────────────────────────────

    import threading
    threads = []
    start = time.perf_counter()
    for _ in range(n_clients):
        t = threading.Thread(target=lambda: [db_fn() for _ in range(requests_per_client)])
        threads.append(t)
        t.start()
    for t in threads:
        t.join()
    elapsed = time.perf_counter() - start
    total_reqs = n_clients * requests_per_client
    print(f"Concurrent Test: {total_reqs} reqs in {elapsed:.2f}s, Throughput: {total_reqs/elapsed:.0f} rps")


# ─── Main ─────────────────────────────────────────────────────────────────────

if __name__ == "__main__":
    print("🚀 Benchmark NoSQL - Comparatif des 4 technologies")
    print("="*60)
    
    N = 10_000  # Réduire pour les tests, 100_000 pour la production
    
    print(f"\n📝 Benchmark Écriture ({N:,} enregistrements)")
    benchmark_write_redis(N)
    benchmark_write_mongodb(N)
    benchmark_write_cassandra(N)
    benchmark_write_neo4j(N)
    
    print(f"\n📖 Benchmark Lecture (1,000 requêtes)")
    benchmark_read_redis()
    benchmark_read_mongodb()
    
    print(f"\n⚡ Test Charge Concurrente (50 clients)")
    def redis_concurrent_fn():
        r = redis.Redis(host='localhost', port=6379, decode_responses=True)
        r.get("key:123")
    benchmark_concurrent(redis_concurrent_fn)
    
    print("\n✅ Benchmark terminé ! Consultez RAPPORT.md pour l'analyse.")
