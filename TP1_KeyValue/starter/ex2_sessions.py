"""
TP1 - Exercice 2 : Sessions utilisateur
Use Case : ShopFast - Gestion des sessions avec expiration (TTL)
"""
import redis
import uuid

r = redis.Redis(host='localhost', port=6379, decode_responses=True)

def create_session(r, user_id):
    """
    Créer une nouvelle session pour un utilisateur.
    Génère un token unique, le stocke dans Redis avec un TTL de 30 minutes (1800 secondes).
    Retourne le token généré.
    """
    session_token = str(uuid.uuid4())
    key = f"session:{session_token}"
    r.setex(key, 1800, user_id)
    return session_token

def get_session(r, session_token):
    """
    Récupérer l'ID utilisateur associé à une session.
    Si la session existe, renouveler son TTL pour 30 minutes (Sliding expiration).
    Retourne l'ID utilisateur ou None si la session a expiré ou n'existe pas.
    """
    key = f"session:{session_token}"
    user_id = r.get(key)
    if user_id:
        r.expire(key, 1800)
    return user_id

def delete_session(r, session_token):
    """
    Supprimer explicitement une session (Logout).
    """
    key = f"session:{session_token}"
    r.delete(key)

if __name__ == "__main__":
    r.flushdb()
    token = create_session(r, "user:42")
    print("Session créée avec token:", token)
    user = get_session(r, token)
    print("Utilisateur récupéré:", user)
    delete_session(r, token)
    print("Utilisateur après déconnexion:", get_session(r, token))
