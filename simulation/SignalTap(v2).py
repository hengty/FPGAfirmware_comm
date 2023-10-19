# Aug 25, 2017

import numpy as np
import matplotlib.pyplot as plt

data_binary = np.loadtxt('data_packet.csv', delimiter=',', dtype=bool, skiprows=6, usecols=(1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19))

vref = 1.8 #Volt
data_decimal = data_binary[:,13]*2**13 + data_binary[:,12]*2**12 + data_binary[:,11]*2**11 + data_binary[:,10]*2**10 + data_binary[:,9]*2**9 + \
				data_binary[:,8]*2**8 + data_binary[:,7]*2**7 + data_binary[:,6]*2**6 + data_binary[:,5]*2**5 + data_binary[:,4]*2**4 + \
				data_binary[:,3]*2**3 + data_binary[:,2]*2**2 + data_binary[:,1]*2**1 + data_binary[:,0]*2**0

decoding = data_binary[:,18]*100+8200
new_bit_clk = data_binary[:,17]*100+8400
new_bit = data_binary[:,16]*100+8600
crc_checked = data_binary[:,15]*100+8800
stop_byte_detected = data_binary[:,14]*100+9000

# plt.figure(dpi=200, figsize=(16,9))
plt.plot(np.arange(np.size(data_decimal))/20000.,data_decimal, label='COM_ADC')
plt.plot(np.arange(np.size(data_decimal))/20000.,decoding, label='decoding')
plt.plot(np.arange(np.size(data_decimal))/20000.,new_bit_clk, label='new_bit_clk')
plt.plot(np.arange(np.size(data_decimal))/20000.,new_bit, label='new_bit')
plt.plot(np.arange(np.size(data_decimal))/20000.,crc_checked, label='crc_checked')
plt.plot(np.arange(np.size(data_decimal))/20000.,stop_byte_detected, label='stop_byte_detected')

plt.xlabel('Time (ms)', fontsize=16)
plt.ylabel('ADC Counts', fontsize=16)
plt.legend(loc='upper right')
plt.show()
# plt.savefig('counts.png')

# first=3809 - 30
# delta=4300
# for i in range(14):
	# waveform = data_decimal[first+i*delta:first+i*delta+200]
	# plt.plot(range(np.size(waveform)), waveform, linestyle=':', marker= '.')
# plt.show()