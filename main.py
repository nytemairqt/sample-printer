from pedalboard import Pedalboard, Chorus, Reverb, Distortion, PitchShift, Delay, Bitcrush, Limiter, LowpassFilter, load_plugin, time_stretch
from pedalboard.io import AudioFile
import soundfile as sf
import numpy as np
from tqdm import tqdm 
import random

from utils import *

# https://github.com/spotify/pedalboard

# to add:
# random sampling (trim to a multiple of analyzed samplerate)
# need filters, stereo widener
# gullfoss (maybe), lfotool (maybe), declick (output clicks only)
# amps/cabs?

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

if __name__ == "__main__":

	# Hyperparameters
	ONLY_REVERB = False

	# Main Loop
	for i in tqdm(range(20)):

		# Need to refresh audio each increment to avoid stacking time-stretches
		audio, samplerate = sf.read('gtr.wav')
		audio = np.float32(audio) # Needs to be 32-bit for time-stretching

		# Pad to make room for long reverb tails
		audio = np.pad(audio, ((0, samplerate*10), (0, 0)))

		# Random Flip (Pre)
		audio = random_flip(audio)

		# Time Stretch
		if roll():
			audio = time_stretch(input_audio=audio, samplerate=samplerate, stretch_factor=random.uniform(0.1, 2.0))		

		# Pedalboard
		proc = Pedalboard([])

		# Pitch Shift
		if roll():
			randomize_pitchshift(pitchshift)
			proc.append(pitchshift)

		# LPF (Pre)
		if roll():
			randomize_lpf_pre(lpf_pre)
			proc.append(lpf_pre)

		# OTT
		if roll():
			proc.append(OTT)

		# Distortion
		if roll():
			randomize_distortion(distortion)
			proc.append(distortion)

		# Driver
		if roll():
			randomize_driver(driver)
			proc.append(driver)

		# Bitcrush
		if roll():
			randomize_bitcrush(bitcrush)
			proc.append(bitcrush)

		# LPF (Post)
		if roll():
			randomize_lpf_post(lpf_post)
			proc.append(lpf_post)

		# Chorus
		if roll():
			randomize_chorus(chorus)
			proc.append(chorus)

		# Supermassive
		if roll():
			randomize_supermassive(supermassive)
			if ONLY_REVERB:
				supermassive.mix = 100.0
			proc.append(supermassive)

		# Limiter
		proc.append(limiter)

		# Apply Pedalboard
		processed = proc(audio, samplerate)

		# Random Flip (Pre)
		processed = random_flip(processed)

		# Write Audio Out
		sf.write(f'output/output{i}.wav', processed, samplerate)