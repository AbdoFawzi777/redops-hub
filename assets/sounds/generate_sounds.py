import os
import math
import wave
import struct

def generate_wav(filename, freq_list, duration=0.4, sample_rate=44100, volume=0.8):
    os.makedirs(os.path.dirname(filename), exist_ok=True)
    num_samples = int(sample_rate * duration)
    with wave.open(filename, 'w') as wav_file:
        wav_file.setnchannels(1)
        wav_file.setsampwidth(2)
        wav_file.setframerate(sample_rate)

        for i in range(num_samples):
            t = float(i) / sample_rate
            # Determine active frequency or sweep
            if len(freq_list) == 1:
                freq = freq_list[0]
            else:
                idx = int((i / num_samples) * len(freq_list))
                freq = freq_list[min(idx, len(freq_list) - 1)]

            value = int(volume * 32767.0 * math.sin(2.0 * math.pi * freq * t))
            data = struct.pack('<h', value)
            wav_file.writeframesraw(data)

def main():
    sounds_dir = r"E:\redops_hub\assets\sounds"

    # 1. Critical Alert Siren (High Siren Sweep)
    generate_wav(os.path.join(sounds_dir, "critical_alert.wav"), [880, 1760, 880, 1760], duration=0.6)

    # 2. High Threat Warning (Beep Beep)
    generate_wav(os.path.join(sounds_dir, "high_alert.wav"), [660, 440, 660], duration=0.4)

    # 3. Chat Comm Ping (Subtle Tactical Ping)
    generate_wav(os.path.join(sounds_dir, "chat_ping.wav"), [1200, 1500], duration=0.25)

    # 4. System Update Chime
    generate_wav(os.path.join(sounds_dir, "system_update.wav"), [523, 659, 784, 1046], duration=0.5)

    print("Audio WAV sound files created successfully!")

if __name__ == "__main__":
    main()
