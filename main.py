from pedalboard import Pedalboard, Chorus, Reverb, load_plugin
from pedalboard.io import AudioFile
import soundfile as sf
import numpy as np
from tqdm import tqdm 
import random

from utils import *

# https://github.com/spotify/pedalboard

# use LIBROSA
# 	it has pitch-shifting, timestretch and a bunch of sound-decomposition & resynthesis tools
# 	pre and post stretch, pre and post shift
# 	pre and post eq, filter, saturation
# pitch shifting & timestretch
# eq, compression, saturation, filter stereo-wideners
# driver (NI), gullfoss (maybe), lfotool (maybe), declick (output clicks only)
# supermassive
# amps/cabs?

print('Loading plugins...')

OTT = load_plugin(r'C:\Program Files\Common Files\VST3\OTT.vst3')
driver = load_plugin(r'C:\Program Files\Common Files\VST3\Driver.vst3')
supermassive = load_plugin(r'C:\Program Files\Common Files\VST3\ValhallaSupermassive.vst3')
amp_roots = load_plugin(r'C:\Program Files\Common Files\VST3\Amped - Roots.vst3')

if __name__ == "__main__":

	ONLY_REVERB = False

	# Main Loop
	# This will be randomized to select a section of a field recording or a sample
	audio, samplerate = sf.read('sample.wav')

	# Pad to make room for long reverb tails
	audio = np.pad(audio, ((0, samplerate*10), (0, 0)))

	# Main Loop
	for i in tqdm(range(20)):
		# Apply Librosa processing

		# Random Flip (Pre)
		audio = random_flip(audio)

		# Pedalboard
		proc = Pedalboard([])

		# OTT
		if roll():
			proc.append(OTT)

		# Driver
		if roll():
			randomize_driver(driver)
			proc.append(driver)

		# Supermassive
		if roll():
			randomize_supermassive(supermassive)
			if ONLY_REVERB:
				supermassive.mix = 100.0
			proc.append(supermassive)

		# Apply Pedalboard
		processed = proc(audio, samplerate)

		# Random Flip (Pre)
		processed = random_flip(processed)

		# Write Audio Out
		sf.write(f'output/output{i}.wav', processed, samplerate)