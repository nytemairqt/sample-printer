import os
from pedalboard import Pedalboard, Chorus, Reverb, Distortion, PitchShift, Delay, Bitcrush, Limiter, LowpassFilter, load_plugin, time_stretch
from pedalboard.io import AudioFile
import soundfile as sf
import numpy as np
from tqdm import tqdm 
import random

from utils import *
from hyperparameters import *

# Pedalboard FX
pitchshift = PitchShift()
chorus = Chorus()
distortion = Distortion()
bitcrush = Bitcrush()

# Plugins

print(f'Loading Plugins...')
OTT = load_plugin(r'C:\Program Files\Common Files\VST3\OTT.vst3')
driver = load_plugin(r'C:\Program Files\Common Files\VST3\Driver.vst3')
supermassive = load_plugin(r'C:\Program Files\Common Files\VST3\ValhallaSupermassive.vst3')

fuse_compressor = load_plugin(r'C:\Program Files\Common Files\VST3\Minimal Audio\Fuse Compressor.vst3')
hybrid_filter = load_plugin(r'C:\Program Files\Common Files\VST3\Minimal Audio\Hybrid Filter.vst3')
rift = load_plugin(r'C:\Program Files\Common Files\VST3\Minimal Audio\Rift.vst3')
rift_feedback_lite = load_plugin(r'C:\Program Files\Common Files\VST3\Minimal Audio\Rift Feedback Lite.vst3')
ripple_phaser = load_plugin(r'C:\Program Files\Common Files\VST3\Minimal Audio\Ripple Phaser.vst3')
flex_chorus = load_plugin(r'C:\Program Files\Common Files\VST3\Minimal Audio\Flex Chorus.vst3')
cluster_delay = load_plugin(r'C:\Program Files\Common Files\VST3\Minimal Audio\Cluster Delay.vst3')
swarm_reverb = load_plugin(r'C:\Program Files\Common Files\VST3\Minimal Audio\Swarm Reverb.vst3')

lpf_pre = load_plugin(r'C:\Program Files\Common Files\VST3\LFOTool.vst3')
lpf_post = load_plugin(r'C:\Program Files\Common Files\VST3\LFOTool.vst3')

# Setup Limiter (to avoid RIP ears)
limiter = Limiter()
limiter.threshold_db = -12.0

INPUT = 'input/segments/'
OUTPUT = 'output/'
input_audio = []

if __name__ == "__main__":	

	# Main Loop
	print('Loading Audio files into pool...')
	for i in tqdm(range(NUM_GENERATIONS)):
		for root, dirs, files in os.walk(INPUT):
			for name in files:
				input_audio.append(f'{INPUT}{name}')

		layers = []
		for j in range(NUM_MAX_LAYERS):
			seed = int(random.randint(0, len(input_audio)-1))
			# Need to refresh audio each increment to avoid stacking time-stretches
			data, samplerate = sf.read(input_audio[seed])
			data = np.float32(data) # Must be float 32			
			layers.append((data, detect_transient(data[:, 0])))

		# Trim To Transient & Align Layers
		aligned = []
		max_length = max(padded.shape[0] for padded, _ in layers)
		for data, transient in layers:
			padded = data[transient:, :]
			padded = np.pad(padded, ((0, max_length - padded.shape[0]), (0,0)))
			aligned.append(padded)
		layered = np.sum(aligned, axis=0)
		audio = layered / np.max(np.abs(layered)) # Normalized	
		audio *= .7 # Headroom

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

		# Fuse Compressor (Minimal Audio)
		if roll() and USING_FUSE_COMPRESSOR:			
			randomize_fuse_compressor(fuse_compressor)
			proc.append(fuse_compressor)

		# Hybrid Filter (Minimal Audio)
		if roll() and USING_HYBRID_FILTER:			
			randomize_hybrid_filter(hybrid_filter)
			proc.append(hybrid_filter)

		# Rift (Minimal Audio)
		if roll() and USING_RIFT:			
			randomize_rift(rift)
			proc.append(rift)

		# Rift Feedback (Minimal Audio)
		if roll() and USING_RIFT_FEEDBACK_LITE:			
			randomize_rift_feedback_lite(rift_feedback_lite)
			proc.append(rift_feedback_lite)

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

		# Ripple Phaser (Minimal Audio)
		if roll() and USING_RIPPLE_PHASER:			
			randomize_ripple_phaser(ripple_phaser)
			proc.append(ripple_phaser)

		# Flex Chorus (Minimal Audio)
		if roll() and USING_FLEX_CHORUS:			
			randomize_flex_chorus(flex_chorus)
			proc.append(flex_chorus)

		# Cluster Delay (Minimal Audio)
		if roll() and USING_CLUSTER_DELAY:			
			randomize_cluster_delay(cluster_delay)
			proc.append(cluster_delay)			

		# Supermassive
		if roll() and USING_SUPERMASSIVE:			
			randomize_supermassive(supermassive)
			if ONLY_REVERB:
				supermassive.mix = 100.0
			proc.append(supermassive)

		# Swarm Reverb (Minimal Audio)
		if USING_SWARM_REVERB:			
			randomize_swarm_reverb(swarm_reverb)
			if ONLY_REVERB:
				swarm_reverb.dry_wet = 100.0
			proc.append(swarm_reverb)

		# Limiter
		if USING_LIMITER:
			proc.append(limiter)

		# Shuffle & Apply Pedalboard FX
		if SHUFFLE_PEDALBOARD:
			random.shuffle(proc)

		processed = proc(audio, samplerate)

		# Random Flip (Post)
		if USING_RANDOM_FLIP_POST:
			processed = random_flip(processed)

		# Write Audio Out
		sf.write(f'{OUTPUT}output{i}.wav', processed, samplerate)
		