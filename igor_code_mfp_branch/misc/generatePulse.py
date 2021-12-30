# -*- coding: utf-8 -*-
"""
Created on Fri Jun 05 09:35:58 2015

@author: Cypher
"""
import numpy as np

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

def GenerateTaus(tau, beta=1, sfx =''):
    '''
    Generate a single exponential for trEFM when applied to the substrate
    
    Parameters
    ----------
    tau : float
        Time constant for the exponential
    beta : float, optional
        Stretching exponent. The default is 1, which means no stretch
    sfx : string, optional
        Suffix for saving files. The default is ''.

    Returns
    -------
    None.

    '''
    print ('Generating tau', tau, 'with beta', beta)
    
    sample_rate = 1.0e8 # sampling rate used in Wavegenerator code
    total_samples = 800000
    pulse_samples = 700000
    
    data = np.arange(total_samples)/sample_rate
    
    data[:pulse_samples] = np.exp(-data[:pulse_samples]/tau)**beta - 1
    data[pulse_samples:] = 0
    
    name = "tau" + sfx + ".dat"
    np.savetxt(name, data, delimiter='\n', fmt ='%.10f')

def GenerateBiTaus(tau1, tau2, amp1=0.5, amp2=0.5, sfx =''):
    '''
    Generate a biexponential 
    Parameters
    ----------
    tau1 : float
        Time constant for the first exponential
    tau2 : float
        Time constant for the second exponential
    amp1 : float, optional
        Amplitude for the first exponential. The default is 0.5.
    amp2 : TYPE, optional
        Amplitude for the second exponential. The default is 0.5.
    sfx : string, optional
        Suffix for saving files. The default is ''.

    Raises
    ------
    ValueError
        If amplitudes do not add to 1, this error is called.

    Returns
    -------
    None.

    '''
    
    if amp1 + amp2 != 1.0:
        raise ValueError("Amp1 + Amp2 must equal 1")
    
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
    
    # Manually changed to generate the original 13 
    # Then fills in the rest
    taus = np.logspace(-6, -3, 500)
    
    # To make the numbers more useful to categorize
    rounds = np.abs([np.floor(np.log10(x)) -2 for x in taus]).astype(int)
    for n, r in enumerate(rounds):
        taus[n] = np.round(taus[n], r) 
    np.savetxt('Taus_used.txt', taus, delimiter='\n', fmt ='%.10f')
    
    for n, t in enumerate(taus):
        
        GenerateTaus(t, beta=1, sfx=str(n))
        
    '''    
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
    '''
  
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