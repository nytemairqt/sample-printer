from pedalboard import Pedalboard, Chorus, Reverb, load_plugin
from pedalboard.io import AudioFile
import soundfile as sf
import numpy as np
from tqdm import tqdm 
import random

supermassive = load_plugin(r'ValhallaSupermassive.vst3')

def randomize_supermassive(supermassive):
	modes =  ['Gemini', 'Hydra', 'Centaurus', 'Sagittarius', 'Great Annihilator', 'Andromeda', 'Lyra', 'Capricorn', 'Triangulum', 'Large Magellanic Cloud', 'Cirrus Major', 'Cirrus Minor', 'Cassiopeia', 'Orion']
	supermassive.mode = modes[random.randint(0, len(modes)-1)]

	#supermassive.mix = random.uniform(0.0, 100.0)
	supermassive.mix = 100.0
	supermassive.width = random.uniform(0.0, 100.0)

	supermassive.delay_ms = random.uniform(10.0, 500.0)
	supermassive.delaywarp = random.uniform(0.0, 100.0)
	supermassive.feedback = random.uniform(50.0, 90.0)
	supermassive.density = random.uniform(80.0, 100.0)

	supermassive.modrate = random.uniform(0.01, 10.0)
	supermassive.moddepth = random.uniform(0.0, 100.0)
	supermassive.lowcut = random.uniform(10.0, 2000.0)
	supermassive.highcut = random.uniform(2000.0, 20000.0)
	
	# Print everything
	print('')
	print('')
	print(f'mode: {supermassive.mode}')
	print(f'mix: {supermassive.mix}')
	print(f'width: {supermassive.width}')
	print(f'delay_ms: {supermassive.delay_ms}')
	print(f'delaywarp: {supermassive.delaywarp}')
	print(f'feedback: {supermassive.feedback}')
	print(f'density: {supermassive.density}')
	print(f'modrate: {supermassive.modrate}')
	print(f'moddepth: {supermassive.moddepth}')
	print(f'lowcut: {supermassive.lowcut}')
	print(f'highcut: {supermassive.highcut}')

if __name__ == "__main__":
	# Main Loop

	audio, samplerate = sf.read('sample.wav')

	# Pad to make room for reverb
	audio = np.pad(audio, ((0, samplerate*10), (0, 0)))

	for i in tqdm(range(100)):
		randomize_supermassive(supermassive)
		effected = supermassive(audio, samplerate)
		sf.write(f'output/output{i}.wav', effected, samplerate)