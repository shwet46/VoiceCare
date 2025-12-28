import firebase_admin
from firebase_admin import credentials, firestore
import os

def init_firestore():
    # Path to your downloaded JSON key
    key_path = os.path.join(os.path.dirname(__file__), '..', 'serviceAccountKey.json')
    
    if not firebase_admin._apps:
        cred = credentials.Certificate(key_path)
        firebase_admin.initialize_app(cred)
    
    return firestore.client()

# Export a single db instance to use everywhere
db = init_firestore()