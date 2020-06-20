# -*- coding: utf-8 -*-
"""
Created on Mon Mar 23 16:23:12 2020

@author: Raj
"""


import scipy.signal as sps
import numpy as np
import argparse


def GenChirp(f_center, f_width = 100e3, length=1e-2, sampling_rate=1e8, name='chirp'):
    
    '''
    Generates a single broad-frequency signal using scipy chirp, writes to name.dat
    
    Important usage regarding the sampling rate:
        The sampling rate here must match that of the wave generator when you load
        this signal. There is a limit of 250 MHz on the 33200 Agilent wave generator,
        but obviously that varies.
    
    f_center : float
        Central frequency for the signal
        
    f_width : float
        The single-sided width of the chirp. Generates signal from f_center - f_width
         to f_center + f_width
         
    length : float
        the timescale of the signal. Keep this length in mind for data acquisition;
        if your chirp is longer than your data acquisition, you will miss many of 
        the frequencies
        
    sampling_rate : int
        Sampling rate of the chirp, based on length/sampling_rate number of steps
        This rate must be consistent on the wave generator or the frequencies will
        be off    
    
    name : str
        Filename for writing the chirp to disk
    
    '''
    tx = np.arange(0, length, 1/sampling_rate) # fixed 100 MHz sampling rate for 10 ms
	
    f_hi = f_center + f_width
    f_lo = np.max([f_center - f_width, 1]) # to ensure a positive number
    
    chirp = sps.chirp(tx, f_lo, tx[-1], f_hi)
    
    if '.dat' not in name:
        name = name + '.dat'
    np.savetxt(name, chirp, delimiter='\n', fmt ='%.10f')
    
    return chirp

def GenManyChirps(f_center, f_width = 100e3, length=1e-2, sampling_rate=1e8):
    '''
    Based on the Agilent manual, the max-frequency is 250 MHz/number_of_points
    The minimum number of points is 8, maximum is 1e6
		
	This creates 3 chirp signals around the first three mechanical resonances
    '''

    name = "chirp_w.dat" 
    GenChirp(f_center, f_width, length, sampling_rate, name)

    name = "chirp_2w.dat" # second electrical resonance
    GenChirp(2*f_center, f_width, length, sampling_rate, name)  
    
    name = "chirp_3w.dat"  # third electrical resonance
    GenChirp(3*f_center, f_width, length, sampling_rate, name)  
    
    name = "chirp_w2.dat"  # second mechanical resonance
    GenChirp(6.25*f_center, f_width, length, sampling_rate, name)  
    
    return

if __name__ == '__main__':
    
    '''
    From command line, usage:
        >> python generate_chirp.py 350000 100000
        
        Generates a 350 kHz +/- 100 kHz chirp. This would be ~14 MB on disk
        
        Defaults to 100 MHz, 10 ms length
    '''
    
    parser = argparse.ArgumentParser()
    parser.add_argument('freq_center', help='Resonance Frequency (Hz)')
    parser.add_argument('freq_width', help='Frequency width (Hz)')
    parser.add_argument('length', help='Length of chirp (s)')

    f_center = float(parser.parse_args().freq_center)
    f_width = float(parser.parse_args().freq_width)
    f_length = float(parser.parse_args().length)
    chirp = GenChirp(f_center, f_width, length=f_length)
    

# Old wavegenerator code

def GeneratePulse(pulse_time,voltage,total_time):
    
    sample_rate = 1.0e7
    total_samples = sample_rate * total_time
    pulse_samples = sample_rate * pulse_time
    
    data = np.zeros(total_samples)
    
    data[:pulse_samples] = voltage
    
    fo = open("Pulse.dat","wb")
    
    for i in range(int(total_samples)):
        fo.write(str(data[i])+"\r")
    fo.close()

def GenerateTaus(tau, beta, sfx =''):
    
    sample_rate = 1.0e8 # sampling rate used in Wavegenerator code
    total_samples = 800000
    pulse_samples = 700000
    
    data = np.arange(total_samples)/sample_rate
    
    data[:pulse_samples] = np.exp(-data[:pulse_samples]/tau)**beta - 1
    data[pulse_samples:] = 0
    
    name = "taub" + sfx + ".dat"
    np.savetxt(name, data, delimiter='\n', fmt ='%.10f')

