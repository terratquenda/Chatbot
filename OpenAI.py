import openai
import os
from pathlib import Path
import speech_recognition as sr
import subprocess
import platform
from openai import OpenAI

# Load API Key securely from environment variables
API_KEY = "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"


# Initialize OpenAI Client
client = OpenAI(api_key=API_KEY)

# Define the path to save speech files
AUDIO_OUTPUT_DIR = Path(os.getcwd()) / "audio_responses"
AUDIO_OUTPUT_DIR.mkdir(exist_ok=True)

def listen_to_user():
    """Capture and transcribe the user's voice input."""
    recognizer = sr.Recognizer()
    with sr.Microphone() as mic:
        print("Listening...")
        try:
            recognizer.adjust_for_ambient_noise(mic)
            audio = recognizer.listen(mic)
            print("Processing...")
            return recognizer.recognize_google(audio, language="ja-JP")
        except sr.UnknownValueError:
            return "すみません、聞き取れませんでした。"
        except sr.RequestError:
            return "音声認識サービスに問題があります。"

def generate_openai_response(user_input):
    """Get a response from OpenAI's ChatGPT API."""
    response = client.chat.completions.create(
        model="gpt-3.5-turbo",
        messages=[
            {"role": "system", "content": "あなたは侍です、侍みたいに喋ってください。"},
            {"role": "user", "content": user_input}
        ],
        temperature=0.7,
    )
    return response.choices[0].message.content

def convert_text_to_speech(text, output_file):
    """Convert OpenAI response text to speech using OpenAI TTS API."""
    response = client.audio.speech.create(
        model="tts-1",
        voice="sage",
        input=text,
    )
    with open(output_file, "wb") as f:
        f.write(response.content)

def play_audio(file_path):
    """Play audio using platform-specific tools."""
    system_name = platform.system()
    if system_name == "Darwin":  # macOS
        subprocess.run(["afplay", file_path])
    elif system_name == "Linux":
        subprocess.run(["aplay", file_path])
    elif system_name == "Windows":
        subprocess.run(["powershell", "-c", f"(New-Object Media.SoundPlayer '{file_path}').PlaySync()"])

def chatbot():
    """Run the voice-based chatbot."""
    print("Voice chatbot is running! Say '終了' to quit.")
    while True:
        user_input = listen_to_user()
        if user_input.lower() in ["終了", "exit"]:
            print("Goodbye!")
            break
        elif "すみません" in user_input or "問題があります" in user_input:
            print(user_input)  # Print the error message
            continue

        print(f"You: {user_input}")
        bot_response = generate_openai_response(user_input)
        print(f"Bot: {bot_response}")

        # Convert the response to speech and save as an audio file
        speech_file_path = AUDIO_OUTPUT_DIR / "response.mp3"
        convert_text_to_speech(bot_response, speech_file_path)

        # Play the audio response
        play_audio(str(speech_file_path))

if __name__ == "__main__":
    chatbot()
