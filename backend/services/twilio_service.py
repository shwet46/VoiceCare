"""
Twilio WhatsApp Service
Service for sending WhatsApp messages using Twilio API
"""

import os
from twilio.rest import Client
from dotenv import load_dotenv

load_dotenv()


class TwilioWhatsAppService:
    def __init__(self):
        """Initialize Twilio client with credentials from environment variables"""
        self.account_sid = os.getenv("TWILIO_ACCOUNT_SID")
        self.auth_token = os.getenv("TWILIO_AUTH_TOKEN")
        self.from_whatsapp_number = os.getenv("TWILIO_WHATSAPP_NUMBER")

        if not all([self.account_sid, self.auth_token, self.from_whatsapp_number]):
            raise ValueError("Missing Twilio credentials. Please check your .env file.")

        self.client = Client(self.account_sid, self.auth_token)

    def send_message(self, to_number, message_body):
        """
        Send a WhatsApp message to a specific number

        Args:
            to_number (str): Recipient's phone number in format: +[country_code][number]
                            Example: +919167586024
            message_body (str): The message content to send

        Returns:
            dict: Response containing message SID and status
        """
        try:
            # Twilio WhatsApp numbers must be prefixed with 'whatsapp:'
            to_whatsapp = f"whatsapp:{to_number}"
            from_whatsapp = f"whatsapp:{self.from_whatsapp_number}"

            message = self.client.messages.create(
                body=message_body, from_=from_whatsapp, to=to_whatsapp
            )

            return {
                "success": True,
                "message_sid": message.sid,
                "status": message.status,
                "to": to_number,
                "message": "Message sent successfully",
            }

        except Exception as e:
            return {"success": False, "error": str(e), "to": to_number}

    def send_bulk_messages(self, contacts, message_body):
        """
        Send the same message to multiple contacts

        Args:
            contacts (list): List of phone numbers
            message_body (str): The message to send

        Returns:
            list: List of response dictionaries for each contact
        """
        results = []
        for contact in contacts:
            result = self.send_message(contact, message_body)
            results.append(result)

        return results
