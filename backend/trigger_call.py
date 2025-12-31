from services.firebase_service import init_firestore

from firebase_admin import messaging

init_firestore()

def trigger_ai_call(fcm_token, caller_name="Voice Care"):
    # Define the data payload
    message = messaging.Message(
        data={
            'type': 'incoming_call',
            'id': 'unique_call_123',
            'nameCaller': caller_name,
            'handle': 'Voice Session',
            'hasVideo': 'false',
        },
        token=fcm_token,
        android=messaging.AndroidConfig(
            priority='high', # Critical for waking up the app
        ),
    )

    # Send message
    response = messaging.send(message)
    print(f"Successfully sent call trigger: {response}")

# Example Usage:
trigger_ai_call("cvwb33MWSfSMsPhfO-9oCi:APA91bF1Wdd1AaMh-n_MeWsVBFnHLqYY-0fJhSF4EupNdak-OCRvN6-8num5MhBXTGpli7I3Nwdv-KTPJJSro6bBaI42I9HMy3qzxbGNJJLMi6EAG9GxfdA")