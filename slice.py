import soundfile as sf
import numpy as np
import os
from tqdm import tqdm

def split_audio_randomly(input_file, output_folder, min_samples, max_samples):
    # Load the audio file with soundfile
    y, sr = sf.read(input_file)  # `y` will be a 2D array if stereo, 1D if mono

    # Total number of samples in the audio file
    total_samples = y.shape[0]
    current_sample = 0
    segment_index = 0

    # Estimate the number of segments for progress tracking
    estimated_segments = total_samples // min_samples

    # Create output folder if it doesn't exist
    os.makedirs(output_folder, exist_ok=True)

    # Randomly split until we reach the end of the audio, with tqdm for progress
    with tqdm(total=estimated_segments, desc="Splitting audio") as pbar:
        while current_sample < total_samples:
            # Randomly choose the segment length within the given range
            segment_length = np.random.randint(min_samples, max_samples)
            end_sample = min(current_sample + segment_length, total_samples)

            # Extract the segment
            segment = y[current_sample:end_sample]

            # Save each segment as a separate audio file
            output_path = os.path.join(output_folder, f"segment_{segment_index}.wav")
            sf.write(output_path, segment, sr)

            # Move to the next segment
            current_sample = end_sample
            segment_index += 1
            pbar.update(1)  # Update tqdm progress bar

    print(f"Audio split into {segment_index} segments with random lengths.")

# Usage example
input_file = 'input/taiko.wav'
output_folder = 'input/segments/'
min_samples = 48000  # Minimum segment length in samples
max_samples = 96000  # Maximum segment length in samples
split_audio_randomly(input_file, output_folder, min_samples, max_samples)
