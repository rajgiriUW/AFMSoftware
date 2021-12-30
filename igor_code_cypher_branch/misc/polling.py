# -*- coding: utf-8 -*-
"""
Created on Wed Jan 22 12:45:01 2020

@author: Raj
"""


'''
Script to constantly poll a folder of data and generate an image from that

USAGE:
    
    Open Anaconda prompt
    Navigate to folder where this file is located
    
    python  polling.py "FOLDER WHERE DATA ARE BEING SAVED"
    
'''

import time
import numpy as np
from watchdog.observers import Observer
from watchdog.events import FileSystemEventHandler
from ffta import line, pixel_utils
from matplotlib import pyplot as plt
import argparse

import pyUSID as usid

class MyHandler(FileSystemEventHandler):
    '''
    Event Handler for polling the FFtrEFM directory for new files
    
    Every time a new file is created, this processes that .ibw as a Line
    
    parameters : dict
        Dictionary of the processing parameters. Found in parameters.cfg
    
    lines : int
        how many lines are expected in this image
    
    n_pixels : int
        how many pixels are in each line
    
    wait_per_line : int
        The number of seconds to wait after a new file event (avoids OS errors)
    
    '''
    def __init__(self, parameters, wait_per_line = 5):
        '''
        Increments lines_loaded every time a new file is corrected
        This method provides a (crude) flag for checking when to stop
        '''
        
        self.lines_loaded = 0
        self.loaded = False   
        
        self.parameters = parameters
        self.lines = parameters['lines_per_image']
        self.n_pixels = parameters['n_pixels']
        
        self.wait_per_line = int(wait_per_line)
        
        
        # initialize the FFtrEFM line data
        self.tfp = np.empty(self.n_pixels)
        self.shift = np.empty(self.n_pixels)
        
    def on_created(self, event):
        '''
        When it detects a new file is there, processes the line then saves
        the tfp and shift data. The processes instananeous frequency are not
        saved as this is a live imaging method
        '''
        
        self.tfp = np.empty(self.n_pixels)
        self.shift = np.empty(self.n_pixels)
        
        if not event.is_directory:

            self.loaded = True            
            time.sleep(self.wait_per_line)

            path = event.src_path.split('\\')
            
            signal = pixel_utils.load.signal(event.src_path)
            this_line = line.Line(signal, self.parameters, self.n_pixels)
            self.tfp, self.shift, _ = this_line.analyze()
            print('Analyzed', path[-1], 'tFP avg =',np.mean(self.tfp), 
                  ' s; shift =', np.mean(self.shift), 'Hz')
            self.loaded = False
            self.lines_loaded += 1
   
     
if __name__ == '__main__':
    
    parser = argparse.ArgumentParser()
    parser.add_argument('path', help='Path where data are being saved')
    parser.add_argument('--tfp_sc_lo', help='tFP color scale minimum', default=0.00012)
    parser.add_argument('--tfp_sc_hi', help='tFP color scale maximum',default=0.00015)
    
    parser.add_argument('--shift_sc_lo', help='shift color scale minimum',default=-100)
    parser.add_argument('--shift_sc_hi', help='tFP color scale maximum',default=0)
    
    path_to_watch = parser.parse_args().path
    print('Loading data from ', path_to_watch)
    
    params_file = path_to_watch + r'\parameters.cfg'
    n_pixels, parameters = pixel_utils.load.configuration(params_file)
    lines = parameters['lines_per_image']

    print('Pixels = ', n_pixels)
    print('Lines = ', lines)
    
    #tfp = np.random.randn(lines, n_pixels)
    #shift = np.random.randn(lines, n_pixels)
    
    tfp = np.zeros([lines, n_pixels])
    shift = np.zeros([lines, n_pixels])

    # initialize event handler
    my_observer = Observer()
    my_event_handler = MyHandler(parameters)
    my_observer.schedule(my_event_handler, path_to_watch, recursive=False)
    my_observer.start()
    
    # initialize plotting
    plt.ion()

    fig, ax = plt.subplots(nrows=1, ncols=2, figsize=(12, 6), tight_layout=True, facecolor='white')

    tfp_ax = ax[0]
    shift_ax = ax[1]

    plt.setp(tfp_ax.get_xticklabels(), visible=False)
    plt.setp(tfp_ax.get_yticklabels(), visible=False)
    plt.setp(shift_ax.get_xticklabels(), visible=False)
    plt.setp(shift_ax.get_yticklabels(), visible=False)

    tfp_ax.set_title('tFP Image!')
    shift_ax.set_title('Shift Image')


    kwargs = {'origin': 'lower', 'x_vec': parameters['FastScanSize'] * 1e6,
              'y_vec': parameters['SlowScanSize'] * 1e6, 'num_ticks': 5, 'stdevs': 3}
    tfp_image, cbar_tfp = usid.viz.plot_utils.plot_map(tfp_ax, tfp,
                                                       cmap='inferno', show_cbar=False, **kwargs)
    shift_image, cbar_sh = usid.viz.plot_utils.plot_map(shift_ax, shift,
                                                        cmap='inferno', show_cbar=False, **kwargs)

#    kwargs = {'origin': 'lower', 'aspect': 'equal'}
#
#    tfp_image = tfp_ax.imshow(tfp * 1e6, cmap='afmhot', **kwargs)
#    shift_image = shift_ax.imshow(shift, cmap='inferno', **kwargs)
#    
#    tfp_sc = tfp[tfp.nonzero()] * 1e6
#    tfp_image.set_clim(vmin=tfp_sc.min(), vmax=tfp_sc.max())
#
#    shift_sc = shift[shift.nonzero()]
#    shift_image.set_clim(vmin=shift_sc.min(), vmax=shift_sc.max())
    
    text = plt.figtext(0.4, 0.1, '')
    text = tfp_ax.text(n_pixels / 2, lines + 3, '')
    plt.show()

    # event handling loop
    try:
        while my_event_handler.lines_loaded < lines:
            time.sleep(1)
            
            if my_event_handler.loaded:
                tfp[my_event_handler.lines_loaded, :] = my_event_handler.tfp[:]
                shift[my_event_handler.lines_loaded, :] = my_event_handler.shift[:]
                
                #tfp_image = tfp_ax.imshow(tfp * 1e6, cmap='afmhot', **kwargs)
                #shift_image = shift_ax.imshow(shift, cmap='inferno', **kwargs)
                
                tfp_image, _ = usid.viz.plot_utils.plot_map(tfp_ax, tfp,
                                                        cmap='inferno', show_cbar=False, **kwargs)
                shift_image, _ = usid.viz.plot_utils.plot_map(shift_ax, shift,
                                                          cmap='inferno', show_cbar=False, **kwargs)

#                tfp_sc = tfp[tfp.nonzero()]
#                tfp_image.set_clim(vmin=tfp_sc.min(), vmax=tfp_sc.max())
#
#                shift_sc = shift[shift.nonzero()]
#                shift_image.set_clim(vmin=shift_sc.min(), vmax=shift_sc.max())
                
                #plt.draw()
                fig.canvas.draw_idle()
                plt.pause(0.0001)
            

    except KeyboardInterrupt:
        my_observer.stop()
        my_observer.join()
        
    print('Lines loaded = ',my_event_handler.lines_loaded)
    
    plotname = path_to_watch + r'\tfp_image.png'
    plt.savefig(plotname)
    
    my_observer.stop()
    my_observer.join()
    