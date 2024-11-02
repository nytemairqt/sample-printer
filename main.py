import os
from pedalboard import Pedalboard, Chorus, Reverb, Distortion, PitchShift, Delay, Bitcrush, Limiter, LowpassFilter, load_plugin, time_stretch
from pedalboard.io import AudioFile
import soundfile as sf
import numpy as np
from tqdm import tqdm 
import random
import glob

import psutil
import time
import threading

from utils import *
from hyperparameters import *

p = psutil.Process(os.getpid())
p.nice(psutil.IDLE_PRIORITY_CLASS) # Alternatively, use psutil.BELOW_NORMAL_PRIORITY_CLASS

# Pedalboard FX
pitchshift = PitchShift()
chorus = Chorus()
distortion = Distortion()
bitcrush = Bitcrush()

# Plugins

lpf_pre = load_plugin(r'C:\Program Files\Common Files\VST3\LFOTool.vst3')
fuse_compressor = load_plugin(r'C:\Program Files\Common Files\VST3\Minimal Audio\Fuse Compressor.vst3')		
hybrid_filter = load_plugin(r'C:\Program Files\Common Files\VST3\Minimal Audio\Hybrid Filter.vst3')	
rift = load_plugin(r'C:\Program Files\Common Files\VST3\Minimal Audio\Rift.vst3')	
rift_feedback_lite = load_plugin(r'C:\Program Files\Common Files\VST3\Minimal Audio\Rift Feedback Lite.vst3')			
driver = load_plugin(r'C:\Program Files\Common Files\VST3\Driver.vst3')
ripple_phaser = load_plugin(r'C:\Program Files\Common Files\VST3\Minimal Audio\Ripple Phaser.vst3')	
lpf_post = load_plugin(r'C:\Program Files\Common Files\VST3\LFOTool.vst3')
flex_chorus = load_plugin(r'C:\Program Files\Common Files\VST3\Minimal Audio\Flex Chorus.vst3')		
cluster_delay = load_plugin(r'C:\Program Files\Common Files\VST3\Minimal Audio\Cluster Delay.vst3')		
supermassive = load_plugin(r'C:\Program Files\Common Files\VST3\ValhallaSupermassive.vst3')	
swarm_reverb = load_plugin(r'C:\Program Files\Common Files\VST3\Minimal Audio\Swarm Reverb.vst3')
OTT = load_plugin(r'C:\Program Files\Common Files\VST3\OTT.vst3')

INPUT = 'input/'
OUTPUT = 'output/'
input_audio = []

plugins = [pitchshift, chorus, distortion, bitcrush, lpf_pre, fuse_compressor, hybrid_filter, rift, rift_feedback_lite, driver, ripple_phaser, lpf_post, flex_chorus, cluster_delay, supermassive, swarm_reverb, OTT]

if __name__ == "__main__":	

	# Main Loop

	print('Loading Audio files into pool...')
	input_audio = glob.glob(os.path.join(INPUT, '**', '*.wav'), recursive=True)

	for i in tqdm(range(NUM_GENERATIONS)):	
		seed = int(random.randint(0, len(input_audio)-1))
		audio, samplerate = sf.read(input_audio[seed])
		audio = np.float32(audio)
		audio /= np.max(np.abs(audio)) # normalize
		audio *= .7 # headroom

		trim_length = samplerate * DURATION
		if USING_DYNAMIC_TRIM and audio.shape[0] > trim_length:
			print(f'Trimming audio to {trim_length} samples.')
			trim_start = random.randint(0, audio.shape[0] - trim_length)
			audio = audio[trim_start:trim_start+trim_length]

		# Random Flip (Pre)
		if USING_RANDOM_FLIP_PRE:
			audio = random_flip(audio)

		# Pad to make room for long reverb tails
		if USING_PAD_AUDIO:
			audio = np.pad(audio, ((0, samplerate*10), (0, 0)))
	
		# Time Stretch
		if roll() and USING_TIME_STRETCH:
			audio = time_stretch(input_audio=audio, samplerate=samplerate, stretch_factor=random.uniform(0.1, 2.0))		

		# Pedalboard
		proc = Pedalboard([])

		print('Setup proc.')
		thread = threading.Thread(target=setup_proc, args=(plugins, proc))
		thread.start()
		thread.join()		

		'''		
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
			for j in range(NUM_RIFTS):								
				randomize_rift(rift)
				proc.append(rift)

		# Rift Feedback (Minimal Audio)
		if roll() and USING_RIFT_FEEDBACK_LITE:			
			randomize_rift_feedback_lite(rift_feedback_lite)
			proc.append(rift_feedback_lite)

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

		# Shuffle Current FX
		if SHUFFLE_PEDALBOARD:
			random.shuffle(proc)

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

		# OTT (Always active)
		if USING_OTT:						
			OTT.Depth = 30.0
			proc.append(OTT)
		'''

		# Limiter
		if USING_LIMITER:
			limiter = Limiter()
			limiter.threshold_db = -12.0
			proc.append(limiter)

		file_path = f'{OUTPUT}output{i}.wav'

		print('Apply proc and write.')
		thread = threading.Thread(target=apply_pedalboard_and_write_out, args=(proc, audio, samplerate, file_path))
		thread.start()
		thread.join()
		time.sleep(0.5)
		