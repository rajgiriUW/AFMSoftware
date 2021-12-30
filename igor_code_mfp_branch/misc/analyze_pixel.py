# -*- coding: utf-8 -*-
"""
Created on Wed Jan 22 12:35:38 2020

@author: Raj
"""

#Script that loads, analyzes, and plots fast free point scan with fit
from ffta.pixel import Pixel
from ffta.pixel_utils.load import signal
from ffta.pixel_utils.load import configuration
import matplotlib.pyplot as plt
import argparse
import os
import numpy as np

def analyze_pixel(ibw_file, param_file):
	'''
	Analyzes a single pixel
	
	Params
	----
	ibw_file : str
		path to *.ibw file
	param_file : str
		path to parameters.cfg file
		
	Returns
	----
	pixel : Pixel
		The pixel object read and analyzed
	'''
	signal_array = signal(ibw_file)
	n_pixels, params = configuration(param_file)
	pixel = Pixel(signal_array, params=params)
	
	plt.ion()
	pixel.analyze()
	#pixel.plot() 
	try:
		plt.plot(pixel.cut, 'r')
		plt.plot(pixel.best_fit, 'g--')
		plt.xlabel('Time Step')
		plt.ylabel('Freq Shift (Hz)')
		plt.show()
		print('tFP is', pixel.tfp, 's')
		
		plt.savefig('pointscan.png')
	
	except:
		print('Exception while plotting')

	return pixel.tfp, pixel

if __name__ == '__main__':
	
	parser = argparse.ArgumentParser()
	parser.add_argument('path', help='folder containing the point scan')
	
	ibw_path = parser.parse_args().path
	ibw_path = ibw_path.replace('"', '')
	os.chdir(ibw_path)
	if os.path.exists(ibw_path + '\pointscan.ibw'):
		tfp, pix = analyze_pixel(ibw_path + '\pointscan.ibw', ibw_path + '\ps_parameters.cfg')
	else:
		ibw_path = ibw_path[:-1]
		tfp, pix = analyze_pixel(ibw_path + '\pointscan.ibw', ibw_path + '\ps_parameters.cfg')

	np.savetxt('pointscan.txt', pix.inst_freq)
	