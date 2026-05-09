# Rapport TP1 - Redis

## 1. Comparaison de performance (hit vs miss)
L'implémentation du pattern Cache-Aside (ex3_cache.py) met en évidence une différence de performance significative entre un "cache hit" et un "cache miss".
- **Cache MISS** : Le système doit interroger la base de données relationnelle sous-jacente qui est relativement lente (simulée à 2 secondes). Le temps de réponse est donc d'au moins ~2000 ms, plus le temps d'écriture dans Redis.
- **Cache HIT** : L'accès à Redis en mémoire vive est extrêmement rapide (quelques millisecondes voire microsecondes localement).
Ainsi, dès le deuxième appel pour un même produit, la latence est drastiquement réduite, rendant le système de ShopFast beaucoup plus réactif.

## 2. Justification des choix de modélisation
- **Produits (`Hash`)** : Nous avons utilisé `HSET` et `HGETALL` pour stocker les produits car un produit possède plusieurs attributs (nom, prix, catégorie, stock) qui peuvent ainsi être lus ou modifiés de manière isolée sans avoir à re-sérialiser l'objet complet à chaque fois.
- **Panier (`Hash`)** : Le panier est stocké avec un hash, où la clé représente l'utilisateur et les champs sont les IDs des produits avec pour valeurs les quantités. La commande `HINCRBY` est parfaite pour ajouter ou supprimer des articles dynamiquement.
- **Historique (`List`)** : L'historique de navigation est implémenté via une liste Redis avec `LPUSH` et tronqué avec `LTRIM` pour ne conserver que les `N` derniers éléments consultés, créant ainsi une taille fixe idéale pour une pagination rapide.
- **Catégories (`Set`)** : Un `Set` garantit l'unicité des produits dans une catégorie et permet l'intersection très rapide (`SINTER`) pour la recherche à facettes (ex: tous les produits dans "promotions" et "téléphones").
- **Leaderboard (`Sorted Set`)** : Le classement des ventes utilise les `ZSET`, où le score est la quantité vendue. Les opérations comme `ZINCRBY` et `ZREVRANGE` permettent de maintenir la liste triée de façon native avec une complexité O(log(N)).

## 3. Réponses aux questions de réflexion
1. **Que se passe-t-il si Redis redémarre ?**
Si Redis est configuré en mode pur "en-mémoire" (sans persistance AOF ou RDB), toutes les données seront perdues. Le cache se reconstruira progressivement à mesure que des Cache MISS surviendront. Cependant, pour des données comme les sessions et les paniers, l'utilisateur devra se reconnecter et refera son panier, entraînant une mauvaise expérience utilisateur. Il faut donc configurer une persistance adéquate.
2. **Comment gérer la cohérence cache/DB en cas d'accès concurrent ?**
Pour garantir la cohérence en cas de forte concurrence (ex: l'achat d'un même article), l'utilisation des transactions MULTI/EXEC associées à la commande `WATCH` (Optimistic Locking) assure qu'une valeur lue dans Redis (comme un stock) n'a pas été modifiée par un autre thread avant de valider la transaction.
3. **Quand un TTL trop court est-il problématique ?**
Un Time-To-Live (TTL) trop court provoque des expirations de cache trop rapides (Cache Thrashing). La base de données principale (ex: PostgreSQL) sera surchargée à chaque expiration car de nombreux "Cache MISS" se produiront, réduisant à néant l'avantage du cache. En deçà d'un certain seuil, le coût de réécriture en cache est supérieur au bénéfice.

## 4. Captures d'écran des tests
![Test ex1 et ex2](./ScreenShoots%20Solution/Screenshot212252.png)
![Test ex3, ex4 et ex5](./ScreenShoots%20Solution/Screenshot212300.png)
