#!usr/bin/python

# Script to parse hex dump of channels and plot it using GNUplot 
# Requirements: Python 2.7 or above, gnuplot utility from Linux
# To install gnuplot: sudo apt-get install gnuplot
# To check python version: which python
# Author: Keshav L Mathur   Date Created: 4/14
# ECE 551 Logic Analyzer Project

import os,sys
import argparse

# Create command line parser
parser = argparse.ArgumentParser()
parser.add_argument("ch_list",help="Comma separated list of channels, eg: 1,2,4 ")
parser.add_argument("--minx",type=int,default=0, help= "Starting sample number")
parser.add_argument("--maxx",type=int,default=1536, help= "Ending sample number")
args = parser.parse_args()

#print "Please enter comma separated numeric list of atleast 1 number"
channels= args.ch_list.split(',')

if int(max(channels)) > 5 or int(min(channels)) < 1:
    print "\nAtleast one channel out of bounds [need 1 to 5]"
    exit()
else:
    print "\nSelected channels:", channels

for ch in channels:
    # Opening channel dump file for specified channel
    dump_file = 'CH'+str(ch)+'dmp.txt'
    try:
        f = open(dump_file,"r")
    except:
        print "\nError: Unable to read dump file %s. Aborting ...\n" % dump_file 
        exit()
    # parse the channel dump file in a list #
    lines = [line.strip() for line in f]

    # Open output .dat file to plot #
    outfile = open("CH" + str(ch) + "_lvl.dat","w")

    # Iterate over each byte and decode signal level #
    i = 0         # Line number for X axis of plot
    for byte in lines:
        a = bin(int(byte,16))[2:].zfill(8)
        
        for t in range(3,-1,-1):
            low  = a[2*t]
            high = a[2*t+1]
            smpl =''
            if(low =='0'and high == '0'):
                smpl =str(i) + ' 0'
            elif(low == '1' and high == '1'):
                smpl =str(i) + ' 1'
            else:
                smpl =str(i) + ' 0.5'
            outfile.write(smpl+'\n')
            i = i +1
    
    outfile.close()

# Generate GNU plot script #
plot_string = ''
term =0
for ch in channels:
    plot_string+="""set term wxt """ + str(term) + """\nplot "CH"""+str(ch)+"""_lvl.dat" with lines\n"""
    term = term +1


plot_scr=""

plot_scr +="""
set title "Channel Dump Output from LA"
set xlabel "Timestamp (samples)"
set ylabel "Logic Level"
set xrange [%d:%d]
set yrange [-1:2]\n""" %(args.minx,args.maxx)


plot_scr += plot_string

plot_scr+="""pause -1 "Hit any key to continue" """
plot_script = open("plot_dmp.scr","w+")
plot_script.write(plot_scr);
plot_script.close()

# launch GNUplot 
os.system("gnuplot plot_dmp.scr")


