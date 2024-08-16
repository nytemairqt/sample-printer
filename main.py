import os
from pedalboard import Pedalboard, Chorus, Reverb, Distortion, PitchShift, Delay, Bitcrush, Limiter, LowpassFilter, load_plugin, time_stretch
from pedalboard.io import AudioFile
import soundfile as sf
import numpy as np
from tqdm import tqdm 
import random

from utils import *
from hyperparameters import *

# https://github.com/spotify/pedalboard

# to add:
# need hpf, stereo widener
# lfotool w/ movement, declick (output clicks only)
# x50iii w/ cab (stereo active)

print('Loading plugins...')

# Plugins
OTT = load_plugin(r'C:\Program Files\Common Files\VST3\OTT.vst3')
driver = load_plugin(r'C:\Program Files\Common Files\VST3\Driver.vst3')
supermassive = load_plugin(r'C:\Program Files\Common Files\VST3\ValhallaSupermassive.vst3')
amp_roots = load_plugin(r'C:\Program Files\Common Files\VST3\Amped - Roots.vst3')

# Filters

lpf_pre = load_plugin(r'C:\Program Files\Common Files\VST3\LFOTool.vst3')
lpf_post = load_plugin(r'C:\Program Files\Common Files\VST3\LFOTool.vst3')

# Pedalboard FX
pitchshift = PitchShift()
chorus = Chorus()
distortion = Distortion()
bitcrush = Bitcrush()

# Setup Limiter (to avoid RIP ears)
limiter = Limiter()
limiter.threshold_db = -12.0

INPUT = 'input/'
OUTPUT = 'output/'
input_audio = []

if __name__ == "__main__":

	# Hyperparameters
	ONLY_REVERB = False

	# Main Loop
	for i in tqdm(range(NUM_GENERATIONS)):

		for root, dirs, files in os.walk(INPUT):
			for name in files:
				input_audio.append(f'{INPUT}{name}')

		seed = int(random.randint(0, len(input_audio)-1))

		# Need to refresh audio each increment to avoid stacking time-stretches
		audio, samplerate = sf.read(input_audio[seed])
		audio = np.float32(audio) # Needs to be 32-bit for time-stretching

		# Trim Audio To Desired Length
		# [n_samples, channels]
		trim_length = samplerate * 5

		if USING_DYNAMIC_TRIM and audio.shape[0] > trim_length:
			print(f'Trimming audio to {trim_length} samples.')
			trim_start = random.randint(0, audio.shape[0] - trim_length)
			audio = audio[trim_start:trim_start+trim_length]

		# Pad to make room for long reverb tails
		if USING_PAD_AUDIO:
			audio = np.pad(audio, ((0, samplerate*10), (0, 0)))

		# Random Flip (Pre)
		if USING_RANDOM_FLIP_PRE:
			audio = random_flip(audio)

		# Time Stretch
		if roll() and USING_TIME_STRETCH:
			audio = time_stretch(input_audio=audio, samplerate=samplerate, stretch_factor=random.uniform(0.1, 2.0))		

		# Pedalboard
		proc = Pedalboard([])

		# Pitch Shift
		if roll() and USING_PITCH_SHIFT:
			randomize_pitchshift(pitchshift)
			proc.append(pitchshift)

		# LPF (Pre)
		if roll() and USING_LPF_PRE:
			randomize_lpf_pre(lpf_pre)
			proc.append(lpf_pre)

		# OTT
		if roll() and USING_OTT:
			proc.append(OTT)

		# Distortion
		if roll() and USING_DISTORTION:
			randomize_distortion(distortion)
			proc.append(distortion)

		# Driver
		if roll() and USING_DRIVER:
			randomize_driver(driver)
			proc.append(driver)

		# Bitcrush
		if roll() and USING_BITCRUSH:
			randomize_bitcrush(bitcrush)
			proc.append(bitcrush)

		# LPF (Post)
		if roll() and USING_LPF_POST:
			randomize_lpf_post(lpf_post)
			proc.append(lpf_post)

		# Chorus
		if roll() and USING_CHORUS:
			randomize_chorus(chorus)
			proc.append(chorus)

		# Supermassive
		if roll() and USING_SUPERMASSIVE:
			randomize_supermassive(supermassive)
			if ONLY_REVERB:
				supermassive.mix = 100.0
			proc.append(supermassive)

		# Limiter
		if USING_LIMITER:
			proc.append(limiter)

		# Apply Pedalboard
		processed = proc(audio, samplerate)

		# Random Flip (Post)
		if USING_RANDOM_FLIP_POST:
			processed = random_flip(processed)

		# Write Audio Out
		sf.write(f'{OUTPUT}output{i}.wav', processed, samplerate)