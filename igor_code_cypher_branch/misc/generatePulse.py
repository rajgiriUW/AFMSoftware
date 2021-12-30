# -*- coding: utf-8 -*-
"""
Created on Fri Jun 05 09:35:58 2015

@author: Cypher
"""
import numpy as np
#import matplotlib.pyplot as plt


def GeneratePulse(pulse_time,voltage,total_time):
    
    print('a')
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
    
    print('a')
    sample_rate = 1.0e8 # sampling rate used in Wavegenerator code
    total_samples = 800000
    pulse_samples = 700000
    
    data = np.arange(total_samples)/sample_rate
    
    data[:pulse_samples] = np.exp(-data[:pulse_samples]/tau)**beta - 1
    data[pulse_samples:] = 0
    
    name = "tau" + sfx + ".dat"
    np.savetxt(name, data, delimiter='\n', fmt ='%.10f')

def GenerateBiTaus(tau1, tau2, amp1=0.5, amp2=0.5, sfx =''):
    """amp1 + amp2 must equal 1!!!"""
    
    if amp1 + amp2 != 1.0:
        raise ValueError("Amp1 + Amp2 must equal 1")
    
    
    print('a')
    sample_rate = 1.0e8 # sampling rate used in Wavegenerator code
    total_samples = 800000
    pulse_samples = 700000
    
    data = np.arange(total_samples)/sample_rate
    
    #data[:pulse_samples] = np.exp(-data[:pulse_samples]/tau)**beta - 1
    #data[pulse_samples:] = 0
    
    data[:pulse_samples] = (amp1 * (np.exp(-data[:pulse_samples]/tau1) - 1) + 
                            amp2 * (np.exp(-data[:pulse_samples]/tau2) - 1) )
    data[pulse_samples:] = 0
    
    name = "tau" + sfx + ".dat"
    np.savetxt(name, data, delimiter='\n', fmt ='%.10f')
    
    #plt.plot(data)


if __name__ == '__main__':

    print('Generating! This is slow, so hang on')
    
    #GenerateBiTaus(50e-6, 300e-6, 0.5, 0.5, '0')
    GenerateTaus(1e-6, 1, '5')
    GenerateTaus(3e-6, 1, '6')
    #GenerateBiTaus(50e-6, 300e-6, 0.9, 0.1, '1')
	#GenerateBiTaus(50e-6, 300e-6, 0.1, 0.9, '2')
    #GenerateBiTaus(10e-6, 300e-6, 0.5, 0.5, '3')
    #GenerateBiTaus(100e-6, 800e-6, 0.5, 0.5, '4')

    GenerateTaus(1e-7, 1, '0')
    GenerateTaus(2e-7, 1, '1')
    GenerateTaus(5e-7, 1, '2')
    GenerateTaus(1e-6, 1, '3')
    GenerateTaus(2e-6, 1, '4')
    GenerateTaus(5e-6, 1, '5')
    GenerateTaus(1e-5, 1, '6')
    GenerateTaus(2e-5, 1, '7')
    GenerateTaus(5e-5, 1, '8')
    GenerateTaus(1e-4, 1, '9')
    GenerateTaus(2e-4, 1, '10')
    GenerateTaus(5e-4, 1, '11')
    GenerateTaus(1e-3, 1, '12')


    """GenerateTaus(1e-8, 1, '0')
    GenerateTaus(3.162e-8, 1, '1')
    GenerateTaus(1e-7, 1, '2')
    GenerateTaus(3.162e-7, 1, '3')
    GenerateTaus(1e-6, 1, '4')
    GenerateTaus(3.162e-6, 1, '5')
    GenerateTaus(1e-5, 1, '6')
    GenerateTaus(3.162e-5, 1, '7')
    GenerateTaus(1e-4, 1, '8')
    GenerateTaus(3.162e-4, 1, '9')
    GenerateTaus(1e-3, 1, '10')"""