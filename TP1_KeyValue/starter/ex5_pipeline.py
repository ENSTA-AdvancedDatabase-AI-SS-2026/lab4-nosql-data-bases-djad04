"""
TP1 - Exercice 5 : Pipeline & Transactions
Use Case : ShopFast - Bulk insert et transactions
"""
import redis

r = redis.Redis(host='localhost', port=6379, decode_responses=True)

def bulk_insert_products(r, products: list):
    """
    Insérer plusieurs produits en utilisant un pipeline Redis.
    products est une liste de dictionnaires.
    """
    pipe = r.pipeline()
    for p in products:
        product_id = p.pop('id')
        pipe.hset(f"product:{product_id}", mapping=p)
    pipe.execute()

def purchase_product(r, user_id, product_id, price):
    """
    Simuler un achat de manière atomique (Transaction MULTI/EXEC)
    - Décrémenter le stock (hincrby -1)
    - Enregistrer la dépense pour l'utilisateur
    """
    key = f"product:{product_id}"
    pipe = r.pipeline()
    while True:
        try:
            pipe.watch(key)
            stock = int(pipe.hget(key, "stock") or 0)
            if stock > 0:
                pipe.multi()
                pipe.hincrby(key, "stock", -1)
                pipe.hincrby(f"user:{user_id}", "spent", price)
                pipe.execute()
                return True
            else:
                pipe.unwatch()
                return False
        except redis.WatchError:
            continue

if __name__ == "__main__":
    r.flushdb()
    
    # Test bulk insert
    products = [
        {"id": 100, "name": "Produit 100", "price": 10},
        {"id": 101, "name": "Produit 101", "price": 20},
        {"id": 102, "name": "Produit 102", "price": 30}
    ]
    bulk_insert_products(r, products)
    print("Produit 101:", r.hgetall("product:101"))
    
    # Init stock
    r.hset("product:101", "stock", 2)
    
    # Test purchase
    success = purchase_product(r, "user:42", 101, 20)
    print(f"Achat 1 (succès attendu) : {success}, Stock restant : {r.hget('product:101', 'stock')}")
    success = purchase_product(r, "user:43", 101, 20)
    print(f"Achat 2 (succès attendu) : {success}, Stock restant : {r.hget('product:101', 'stock')}")
    success = purchase_product(r, "user:44", 101, 20)
    print(f"Achat 3 (échec attendu - plus de stock) : {success}")
