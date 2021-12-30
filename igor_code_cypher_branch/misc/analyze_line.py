# -*- coding: utf-8 -*-
"""
Created on Wed Jan 22 12:35:38 2020

@author: Raj
"""

#Script that loads, analyzes, and plots fast free point scan with fit
from ffta.pixel import Pixel
from ffta.line import Line
from ffta.pixel_utils.load import signal
from ffta.pixel_utils.load import configuration
import matplotlib.pyplot as plt
import argparse
import os
import numpy as np

def analyze_line(ibw_file, param_file):
	'''
	Analyzes a single line, returns to Igor
	
	Params
	----
	ibw_file : str
		path to *.ibw file
	param_file : str
		path to parameters.cfg file
		
	Returns
	----
	tfp_l: ndArray
		The extracted tFP values from the given line
	shift_l : ndArray
		The extracted shift values from the given line
	'''
	signal_array = signal(ibw_file)
	n_pixels, params = configuration(param_file)
	line = Line(signal_array, params=params, n_pixels=n_pixels)
	
	tfp, shift, _ = line.analyze()

	return tfp, shift

if __name__ == '__main__':
	
	parser = argparse.ArgumentParser()
	parser.add_argument('lineibw', help='line .ibw to analyze')
	parser.add_argument('params', help='params.cfg file to use')
	
	ibw_path = parser.parse_args().lineibw
	params = parser.parse_args().params
	ibw_path = ibw_path.replace('"', '')
	params = params.replace('"', '')
	if params[0] == ' ':
		params = params[1:]
	print(params)
	folder_path = ibw_path.split('\\')[:-1]
	folder_path = '\\'.join(folder_path)
	os.chdir(folder_path)
	if os.path.exists(ibw_path):
		tfp, shift = analyze_line(ibw_path, params)
	else:
		ibw_path = ibw_path[:-1]
		tfp, shift = analyze_line(ibw_path, params)

	np.savetxt('line_tfp.txt', tfp)
	np.savetxt('line_shift.txt', shift)

	