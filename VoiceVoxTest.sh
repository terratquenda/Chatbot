import os
import platform
import subprocess
from pathlib import Path
import requests
import speech_recognition as sr
from openai import OpenAI

# Load API Key securely from environment variables (or directly here)
API_KEY = //can't show
# Initialize OpenAI Client
client = OpenAI(api_key=API_KEY)

# Path to save audio responses
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
        model="gpt-4o",
        messages=[
            {"role": "system", "content": "寂しい口調で喋って"},
            {"role": "user", "content": user_input}
        ],
        temperature=0.7,
    )
    return response.choices[0].message.content

def convert_text_to_speech(text, output_file, speaker_id=2):
    """Convert text to speech using local VOICEVOX engine."""
    try:
        # Step 1: Generate audio query
        query_url = "http://127.0.0.1:50021/audio_query"
        synthesis_url = "http://127.0.0.1:50021/synthesis"

        query_response = requests.post(query_url, params={
            "text": text,
            "speaker": speaker_id
        })
        query_response.raise_for_status()
        query_data = query_response.json()

        # Step 2: Synthesize voice
        synthesis_response = requests.post(
            synthesis_url,
            params={"speaker": speaker_id},
            json=query_data,
            headers={"Content-Type": "application/json"}
        )
        synthesis_response.raise_for_status()

        with open(output_file, "wb") as f:
            f.write(synthesis_response.content)

    except Exception as e:
        print("音声合成エラー:", e)

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
    print("VOICEVOX Chatbot is running! Say '終了' or 'exit' to quit.")
    while True:
        user_input = listen_to_user()
        if user_input.lower() in ["終了", "exit"]:
            print("👋 Goodbye!")
            break
        elif "すみません" in user_input or "問題があります" in user_input:
            print(user_input)  # Print the error message
            continue

        print(f"You: {user_input}")
        bot_response = generate_openai_response(user_input)
        print(f"Bot: {bot_response}")

        # Convert the response to speech using VOICEVOX
        speech_file_path = AUDIO_OUTPUT_DIR / "response.wav"
        convert_text_to_speech(bot_response, speech_file_path)

        # Play the audio response
        play_audio(str(speech_file_path))

if __name__ == "__main__":
    chatbot()
