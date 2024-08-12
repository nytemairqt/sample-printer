import random
import numpy as np 

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

def randomize_supermassive(supermassive):
	# Randomizes all relevant SuperMassive parameters
	modes =  ['Gemini', 'Hydra', 'Centaurus', 'Sagittarius', 'Great Annihilator', 'Andromeda', 'Lyra', 'Capricorn', 'Triangulum', 'Large Magellanic Cloud', 'Cirrus Major', 'Cirrus Minor', 'Cassiopeia', 'Orion']
	supermassive.mode = modes[random.randint(0, len(modes)-1)]

	supermassive.mix = random.uniform(0.0, 100.0)
	supermassive.width = random.uniform(0.0, 100.0)

	supermassive.delay_ms = random.uniform(10.0, 500.0)
	supermassive.delaywarp = random.uniform(0.0, 100.0)
	supermassive.feedback = random.uniform(50.0, 90.0)
	supermassive.density = random.uniform(80.0, 100.0)

	supermassive.modrate = random.uniform(0.01, 10.0)
	supermassive.moddepth = random.uniform(0.0, 100.0)
	supermassive.lowcut = random.uniform(10.0, 2000.0)
	supermassive.highcut = random.uniform(2000.0, 20000.0)

def randomize_driver(driver):
	# Randomizes all relevant Driver parameters
	driver_filter_types = ["LPF", "Notch"]
	driver_polarities = ["+", "-"]
	driver_ranges = ["Low", "High"]
	driver.resonance = random.uniform(0.0, 9.9)
	driver.frequency = random.uniform(53, 30063) # ???
	driver.distortion = random.uniform(0.1, 9.9)
	driver.color = random.uniform(0.1, 9.9)
	driver.filter_type = driver_filter_types[random.randint(0, 1)]
	driver.smooth = random.uniform(0.0, 9.9)
	driver.release = random.uniform(0.1, 9.9)
	driver.f_env_modulation = random.uniform(0.1, 9.9)
	driver.f_env_polarity = driver_polarities[random.randint(0, 1)]
	driver.d_env_polarity = driver_polarities[random.randint(0, 1)]
	driver.d_env_modulation = random.uniform(0.1, 9.9)
	driver.am_env_modulation = random.uniform(-9.9, 9.9)
	driver.rate = random.uniform(0.03, 24.7)
	driver.range = driver_ranges[random.randint(0, 1)]
	driver.f_am_modulation = random.uniform(0.1, 9.9)
	driver.d_am_modulation = random.uniform(0.1, 9.9)