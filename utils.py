import random
import numpy as np 
from scipy.signal import find_peaks
import soundfile as sf
from hyperparameters import * 
from pedalboard import load_plugin

def load_plugins():
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

	return OTT, driver, supermassive, fuse_compressor, hybrid_filter, rift, rift_feedback_lite, ripple_phaser, flex_chorus, cluster_delay, swarm_reverb, lpf_pre, lpf_post

def detect_transient(audio, threshold=0.1):
	# Calculate the envelope by taking the absolute of the signal
	envelope = np.abs(audio)
	peaks, _ = find_peaks(envelope, height=threshold)
	return peaks[0] if len(peaks) > 0 else 0  # First transient location or 0 if none found

def roll():
	# Random coin flip
	return bool(random.getrandbits(1))

def random_flip(audio):
	# Randomly Reverses the buffer and channels
	if roll():
		audio = np.flip(audio, 0)
	if roll():
		audio = np.flip(audio, 1)
	return audio

def randomize_lpf_pre(instance):
	# Randomizes the pre-fx lowpass filter (static LFOtool filter)
	instance.vol = 0.0
	instance.f_cutoff = random.uniform(21.0, 14700.0)
	instance.f_on_off = 'FILT ON'

def randomize_lpf_post(instance):
	# Randomizes the pre-fx lowpass filter (static LFOtool filter)
	instance.vol = 0.0
	instance.f_cutoff = random.uniform(21.0, 14700.0)
	instance.f_on_off = 'FILT ON'

def randomize_pitchshift(instance):
	# Randomizes the pitch in semitones, can be used in a Pedalboard object
	instance.semitones = random.uniform(-12.0, 12.0)

def randomize_chorus(instance):
	# Randomizes all relevant Chorus parameters
	instance.rate_hz = random.uniform(0.0, 100.0)
	instance.depth = random.uniform(0.0, 1.0)
	instance.centre_delay_ms = random.uniform(1.0, 15.0)
	instance.feedback = random.uniform(0.0, 0.9)
	instance.mix = random.uniform(0.0, 1.0)

def randomize_distortion(instance):
	# Randomizes all relevant Distortion parameters
	instance.drive_db = random.uniform(0.0, 40.0)

def randomize_bitcrush(instance):
	# Randomizes all relevant Bitcrush parameters
	instance.bit_depth = random.uniform(1.0, 16.0)

def randomize_supermassive(instance):
	# Randomizes all relevant SuperMassive parameters
	modes =  ['Gemini', 'Hydra', 'Centaurus', 'Sagittarius', 'Great Annihilator', 'Andromeda', 'Lyra', 'Capricorn', 'Triangulum', 'Large Magellanic Cloud', 'Cirrus Major', 'Cirrus Minor', 'Cassiopeia', 'Orion']
	instance.mode = modes[random.randint(0, len(modes)-1)]
	instance.mix = random.uniform(0.0, 100.0)
	instance.width = random.uniform(0.0, 100.0)
	instance.delay_ms = random.uniform(10.0, 500.0)
	instance.delaywarp = random.uniform(0.0, 100.0)
	instance.feedback = random.uniform(50.0, 90.0)
	instance.density = random.uniform(80.0, 100.0)
	instance.modrate = random.uniform(0.01, 10.0)
	instance.moddepth = random.uniform(0.0, 100.0)
	instance.lowcut = random.uniform(10.0, 2000.0)
	instance.highcut = random.uniform(2000.0, 20000.0)

def randomize_driver(instance):
	# Randomizes all relevant Driver parameters
	driver_filter_types = ["LPF", "Notch"]
	driver_polarities = ["+", "-"]
	driver_ranges = ["Low", "High"]
	instance.resonance = random.uniform(0.0, 9.9)
	instance.frequency = random.uniform(53, 30063) # ???
	instance.distortion = random.uniform(0.1, 9.9)
	instance.color = random.uniform(0.1, 9.9)
	instance.filter_type = driver_filter_types[random.randint(0, 1)]
	instance.smooth = random.uniform(0.0, 9.9)
	instance.release = random.uniform(0.1, 9.9)
	instance.f_env_modulation = random.uniform(0.1, 9.9)
	instance.f_env_polarity = driver_polarities[random.randint(0, 1)]
	instance.d_env_polarity = driver_polarities[random.randint(0, 1)]
	instance.d_env_modulation = random.uniform(0.1, 9.9)
	instance.am_env_modulation = random.uniform(-9.9, 9.9)
	instance.rate = random.uniform(0.03, 24.7)
	instance.range = driver_ranges[random.randint(0, 1)]
	instance.f_am_modulation = random.uniform(0.1, 9.9)
	instance.d_am_modulation = random.uniform(0.1, 9.9)

# Minimal Audio

def randomize_fuse_compressor(instance):
	instance.dry_wet = random.randint(0, 100)
	instance.up_ratio = random.randint(0, 200)
	instance.down_ratio = random.randint(0, 200)
	instance.up_threshold = random.randint(-100, 100)
	instance.down_threshold = random.randint(-100, 100)
	instance.tilt = random.uniform(-24.0, 24.0)
	instance.attack = random.uniform(0.1, 500.0)
	instance.release = random.uniform(1.0, 996.0)
	instance.soft_knee = random.uniform(0.0, 60.0)
	instance.channel_link = random.randint(0, 100)

def randomize_hybrid_filter(instance):
	instance.dry_wet = random.randint(0, 100)
	instance.cutoff = random.randint(20, 20000)
	instance.resonance = random.uniform(0.0, 100.0)
	instance.spread = random.uniform(-100.0, 100.0)
	instance.morph = random.randint(0, 100)
	instance.amp_mod = random.randint(0, 100)
	instance.low_band = random.randint(20, 20000)
	instance.cutoff_mod = random.uniform(-200.0, 200.0)
	instance.morph_mod = random.uniform(-200.0, 200.0)

def randomize_rift_feedback_lite(instance):
	notes = ['C-1', 'C♯-1', 'D-1', 'D♯-1', 'E-1', 'F-1', 'F♯-1', 'G-1', 'G♯-1', 'A-1', 'A♯-1', 'B-1', 'C0', 'C♯0', 'D0', 'D♯0', 'E0', 'F0', 'F♯0', 'G0', 'G♯0', 'A0', 'A♯0', 'B0', 'C1', 'C♯1', 'D1', 'D♯1', 'E1', 'F1', 'F♯1', 'G1', 'G♯1', 'A1', 'A♯1', 'B1', 'C2', 'C♯2', 'D2', 'D♯2', 'E2', 'F2', 'F♯2', 'G2', 'G♯2', 'A2', 'A♯2', 'B2', 'C3', 'C♯3', 'D3', 'D♯3', 'E3', 'F3', 'F♯3', 'G3', 'G♯3', 'A3', 'A♯3', 'B3', 'C4', 'C♯4', 'D4', 'D♯4', 'E4', 'F4', 'F♯4', 'G4', 'G♯4', 'A4', 'A♯4', 'B4', 'C5', 'C♯5', 'D5', 'D♯5', 'E5', 'F5', 'F♯5', 'G5', 'G♯5', 'A5', 'A♯5', 'B5', 'C6', 'C♯6', 'D6', 'D♯6', 'E6', 'F6', 'F♯6', 'G6', 'G♯6', 'A6', 'A♯6', 'B6', 'C7']	
	instance.feedback_mix = random.randint(0, 100)
	instance.frequency = notes[random.randint(0, len(notes)-1)]
	instance.feedback = random.uniform(-99.0, 99.0)
	instance.mode = random.randint(0, 100)
	instance.lowpass = random.randint(20, 20000)
	instance.highpass = random.randint(5, 5000)
	instance.spread = random.uniform(-100.0, 100.0)

def randomize_rift(instance):
	instance.drive = random.uniform(0.0, 24.0) # keep an eye on me
	instance.stages = random.randint(0, 5)
	instance.positive_type = random.randint(0, 29)
	instance.positive_shape = random.uniform(0.0, 1.0)
	instance.negative_type = random.randint(0, 29)
	instance.positive_shape = random.uniform(0.0, 1.0)
	instance.blend = random.uniform(-1.0, 1.0)
	instance.blend_mode = random.randint(0, 1)
	instance.stereo_mode = random.randint(0, 4)
	instance.shape_link = random.randint(0, 1)
	instance.dry_wet = random.randint(0, 100)

def randomize_ripple_phaser(instance):
	instance.dry_wet = random.randint(0, 100)
	instance.mod_depth = random.uniform(-100.0, 100.0)
	rates = ['1/64', '1/32 T', '1/64 D', '1/32', '1/16 T', '1/32 D', '1/16', '1/8 T', '1/16 D', '1/8', '1/4 T', '1/8 D', '1/4', '1/2 T', '1/4 D', '1/2', '1/1 T', '1/2 D', '1 Bar']
	instance.rate = rates[random.randint(0, len(rates)-1)]
	instance.randomize = random.randint(0, 100)	
	shapes = ['SINE', 'TRIANGLE', 'RAMP', 'SQUARE']
	instance.shape = shapes[random.randint(0, len(shapes)-1)]
	angles = [f"{angle}°" for angle in range(-180, 181)]
	instance.offset = angles[random.randint(0, len(angles)-1)]
	instance.mod_balance = random.uniform(-100.0, 100.0)
	instance.feedback = random.randint(0, 100)
	instance.bend = random.uniform(-100.0, 100.0)
	instance.center = random.randint(40, 10000)
	instance.spread = random.uniform(-100.0, 100.0)
	instance.stereo = random.uniform(-100.0, 100.0)

def randomize_flex_chorus(instance):
	instance.dry_wet = random.randint(0, 100)
	instance.time = random.randint(0, 100)
	instance.mod_depth = random.randint(0, 100)
	instance.rate = random.uniform(0.01, 20.0)
	instance.randomize = random.randint(0, 100)
	instance.width = random.randint(0, 100)
	instance.feedback = random.randint(0, 100)
	instance.highpass = random.randint(20, 2500)
	instance.lowpass = random.randint(160, 20000)

def randomize_cluster_delay(instance):
	times = ['1/128', '1/64 T', '1/128 D', '1/64', '1/32 T', '1/64 D', '1/32', '1/16 T', '1/32 D', '1/16', '1/8 T', '1/16 D', '1/8', '1/4 T', '1/8 D', '1/4', '1/2 T', '1/4 D', '1/2', '1 Bar T', '1/2 D', '1 Bar', '1 Bar D']
	instance.dry_wet = random.randint(0, 100)
	instance.time = times[random.randint(0, len(times)-1)]
	instance.feedback = random.uniform(0.0, 100.0)
	instance.crossfeed = random.uniform(0.0, 100.0)
	instance.spread = random.uniform(-100.0, 100.0)
	instance.lowpass = random.randint(20, 20000)
	instance.highpass = random.randint(5, 10000)
	instance.scatter = random.uniform(-100.0, 100.0)
	instance.spacing = random.uniform(-100.0, 100.0)
	instance.ramp = random.uniform(-100.0, 100.0)
	instance.depth = random.uniform(0.0, 100.0)
	instance.rate = random.uniform(0.1, 20.0)

def randomize_swarm_reverb(instance):	
	instance.dry_wet = random.randint(0, 100)
	instance.size = random.randint(0, 100)
	instance.decay = random.randint(50, 100)
	instance.balance = random.randint(0, 100)
	instance.diffusion = random.randint(0, 100)
	instance.damping = random.randint(0, 100)
	instance.attack = random.randint(0, 100)
	instance.depth = random.randint(0, 100)
	instance.rate = random.uniform(0.01, 20.0)
	instance.highpass = random.randint(10, 10000)
	instance.lowpass = random.randint(20, 20000)
	instance.high_shelf_freq = random.randint(100, 15000)
	instance.high_shelf_gain = random.uniform(-36.0, -0.5)
	instance.feedback = random.randint(0, 100)
	instance.width = random.randint(0, 100)

	