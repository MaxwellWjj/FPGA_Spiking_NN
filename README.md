# FPGA_Spiking_NN
CORDIC-SNN, an FPGA implementation based on "Unsupervised learning of digital recognition using STDP" published in 2015, frontiers

## Introduction
This project aims to evaluate different CORDIC-based SNN hardware implementations in classification performance, energy efficiency and latency etc. For more details, please refer to
our published paper:  
`J. Wu et al., "Efficient Design of Spiking Neural Network With STDP Learning Based on Fast CORDIC," in IEEE Transactions on Circuits and Systems I: 
Regular Papers, vol. 68, no. 6, pp. 2522-2534, June 2021, doi: 10.1109/TCSI.2021.3061766.`

## Open source
- The codes in this branch includes verilog files which belongs to FPGA implementation. In ./cordic_codes, all the evaluated CORDIC types are designed here.
- For the source code of algorithm-level evaluation (i.e. classification performance in MNIST), please refer to the other branch: MaxwellWjj/ULIIC_SNN_library.
  
