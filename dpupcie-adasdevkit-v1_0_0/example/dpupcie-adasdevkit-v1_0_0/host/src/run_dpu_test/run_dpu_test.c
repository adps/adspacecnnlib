#include <stdio.h>
#include <stdint.h>
#include <string.h>
#include <stdlib.h>
#include <unistd.h>

#include <adxdma.h>


#define TRUE 1
#define FALSE 0

extern int create_dpu_iword(int relu,int conv3x3,int use_maxpool,int stride2, int feature_image_width, int number_of_features, int mp_feature_image_width, int mp_number_of_features, int number_of_active_neurons, int throttle_rate, uint64_t weight_start_address, uint64_t features_start_address, uint64_t output_start_address, uint32_t output_address_increment, uint64_t pre_mp_output_start_address, uint32_t pre_mp_output_address_increment, uint64_t concat_feature_start_address, int concat_feature_count1, int concat_feature_count2, int concat_feature_rescale_enable, uint64_t next_iword_addr, int next_iword_enable, uint32_t *dpu_iword);

extern int read_xcaffe_file(char *xcaffe_filename, char *layer_name, char *scale_layer_name, char *bn_layer_name, int has_bias, double weight_scaling, int layer_size,int input_mask_height, int input_mask_width, int input_no_features, int neuron_skip, int16_t *mem);

#define NLAYERS 30
#define WORKING_MEM_OFFSET (16*1024*1024)
#define BUFSIZE (20*1024*1024)

typedef struct model_def {
  char *conv;
  char *scale;
  char *bn;
  int  bias;
  int  size;
  int  mask;
  int  features;
  int  skip;
  int  relu;
  int  maxp;
  int  fwidth;
  int  stride2;
  int  throttle;
  int  ip;
  int  op;
  int  op_seq;
} MODEL_DEF_TYPE;

int main(int argc, char* argv[])
{
  char *membuf;
  

  int16_t *pweight_mem;
  uint32_t *piword_mem;
  int weight_offset;
  int iword_offset;
  int next_iword_offset;
  int next_iword_enable;
  int i;


  int max_layer;
  int run_one_layer;

 

  const MODEL_DEF_TYPE layer[NLAYERS]={
    {"layer0-conv","layer0-scale","layer0-bn",0,16,3,3,0,1,1,416,0,32,0,2,0},
    {"layer2-conv","layer2-scale","layer2-bn",0,32,3,16,0,1,1,208,0,64,2,4,0},
    {"layer4-conv","layer4-scale","layer4-bn",0,64,3,32,0,1,1,104,0,128,4,6,0},
    {"layer6-conv","layer6-scale","layer6-bn",0,128,3,64,0,1,1,52,0,256,6,8,0},
    // Layer 8 has 256 neurons, so split into 2 sequential runs
    {"layer8-conv","layer8-scale","layer8-bn",0,128,3,128,0,1,1,26,0,256,8,10,2},  // Note also need to enable ODM2 - index 4
    {"layer8-conv","layer8-scale","layer8-bn",0,128,3,128,128,1,1,26,0,256,8,10,2}, // Note also need to enable ODM2 - index 5
    // Layer 10 has 512 neurons, so split into 4 sequential runs
    {"layer10-conv","layer10-scale","layer10-bn",0,128,3,256,0,1,0,13,0,256,10,11,4},    
    {"layer10-conv","layer10-scale","layer10-bn",0,128,3,256,128,1,0,13,0,256,10,11,4},
    {"layer10-conv","layer10-scale","layer10-bn",0,128,3,256,256,1,0,13,0,256,10,11,4},
    {"layer10-conv","layer10-scale","layer10-bn",0,128,3,256,384,1,0,13,0,256,10,11,4},
    // Layer 11 has 1024 neurons, so split into 8 sequential runs
    {"layer11-conv","layer11-scale","layer11-bn",0,128,3,512,0,1,0,13,0,256,11,12,8},    
    {"layer11-conv","layer11-scale","layer11-bn",0,128,3,512,128,1,0,13,0,256,11,12,8},
    {"layer11-conv","layer11-scale","layer11-bn",0,128,3,512,256,1,0,13,0,256,11,12,8},
    {"layer11-conv","layer11-scale","layer11-bn",0,128,3,512,384,1,0,13,0,256,11,12,8},
    {"layer11-conv","layer11-scale","layer11-bn",0,128,3,512,512,1,0,13,0,256,11,12,8},    
    {"layer11-conv","layer11-scale","layer11-bn",0,128,3,512,640,1,0,13,0,256,11,12,8},
    {"layer11-conv","layer11-scale","layer11-bn",0,128,3,512,768,1,0,13,0,256,11,12,8},
    {"layer11-conv","layer11-scale","layer11-bn",0,128,3,512,896,1,0,13,0,256,11,12,8},
    // Layer 12 has 256 Neurons
    {"layer12-conv","layer12-scale","layer12-bn",0,128,1,1024,0,1,0,13,0,384,12,13,2},    
    {"layer12-conv","layer12-scale","layer12-bn",0,128,1,1024,128,1,0,13,0,384,12,13,2},
    // Layer 13 has 512 Neurons
    {"layer13-conv","layer13-scale","layer13-bn",0,128,3,256,0,1,0,13,0,256,13,14,4},    
    {"layer13-conv","layer13-scale","layer13-bn",0,128,3,256,128,1,0,13,0,256,13,14,4},
    {"layer13-conv","layer13-scale","layer13-bn",0,128,3,256,256,1,0,13,0,256,13,14,4},    
    {"layer13-conv","layer13-scale","layer13-bn",0,128,3,256,384,1,0,13,0,256,13,14,4},
    // Layer 14 has 45 Neurons
    {"layer14-conv","","",1,45,1,512,0,0,0,13,0,90,14,15,0},
    // Layer 17 has 128 Neurons reading from layer 12
    {"layer17-conv","layer17-scale","layer17-bn",0,128,1,256,0,1,0,13,0,384,13,20,0}, // index 25
    // Layers 18 and 19 (layer 18 is a rescale of layer 17 output, layer 19 concats withn layer 8 ODM2 output )
    // Layer 20 implements layers 18 and 19 in its input stream : 256 neurons so 2 sequential runs
    {"layer20-conv","layer20-scale","layer20-bn",0,128,1,384,0,1,0,26,0,384,20,21,2}, // index 26
    {"layer20-conv","layer20-scale","layer20-bn",0,128,1,384,128,1,0,26,0,384,20,21,2}, // index 27
    // Layer 21 has 45 Neurons
    {"layer21-conv","","",1,45,1,256,0,0,0,26,0,90,21,22,0} // index 28
  };
   
  //const char model_filename[128] = "../../../../../../onelayerdpu/data/dk_tiny-yolov3_416_416_5.txt";
  //const char input_filename[128] = "../../../../../../onelayerdpu/data/input_data.txt";
  const char model_filename[128] = "dk_tiny-yolov3_416_416_5.txt";
  const char input_filename[128] = "input_data.txt";

  // Address table for input and output data for layers, matching model layers
  const uint64_t layer_ip_startoffset[23] = {0,  // Input image ~ 512k
					     0,  // Not Used
					     512*1024, // Input Layer 2 ~ 1024k
					     0, // Not used
					     (1024+512)*1024, // Input Layer 4 ~340k
					     0, // Not Used
					     2048*1024, // Input Layer 6 ~173k
					     0, // Not Used
					     (2048+256)*1024, // Input Layer 8 ~86k
					     0, // Not Used
					     (2048+256+128)*1024, // Input Layer 10 ~43k
					     (2048+512)*1024, // Input Layer 11 ~86k
					     (2048+512+128)*1024, //Input Layer 12 ~173k
					     (2048+512+128+256)*1024, //Input Layer 13 ~43k
					     3072*1024, // Input Layer 14
					     (3072+64)*1024, // Output Layer 14 ~7k
					     0, // Not Used
					     (3072+128)*1024, // Input Layer 17 ~43k
					     0, // Not Used
					     (3072+192)*1024, // Second input for layer 20 ~173k
					     (3072+448)*1024, // First input for layer 20 ~21k
					     (3072+512)*1024, // Input Layer 21 ~173k
					     (3072+768)*1024}; // Output Layer 21
  // Required space, without re-use and with margins, is less than 4MB
					     

  ADXDMA_HDEVICE hDevice = ADXDMA_NULL_HDEVICE;
  ADXDMA_HDMA hDMAEngine = ADXDMA_NULL_HDMA;
  ADXDMA_HWINDOW hWindow = ADXDMA_NULL_HWINDOW;
  ADXDMA_STATUS status;
  ADXDMA_DEVICE_INFO deviceInfo;
  ADXDMA_WINDOW_INFO windowInfo;

  int deviceIndex = 0;
  int dmaEngineIndex =0;
  int dmaTransferSize = BUFSIZE;
  int liteWindowIndex = 0;
					     
  FILE *fid;

   if (argc>1)
    {
      max_layer = atoi(argv[1]);
      if (max_layer >29)
	max_layer =29;
    }
  else
    max_layer = 29;

   if (argc>2)
     run_one_layer = 1;
   else
     run_one_layer=0;


  membuf=(char *) malloc(BUFSIZE);  // Allocate BUFSIZE buffer

  piword_mem = (uint32_t *) membuf;
  pweight_mem = (int16_t *) (&membuf[8192]);  // Skip over 8 kbytes for IWORD memory
  weight_offset = 8192;
  iword_offset =0; 

  for (i=0;i<max_layer;i++)
    {     
      int n;
      uint64_t concat_feature_start_address;
      int concat_feature_count1;
      int concat_feature_count2; 
      int concat_feature_rescale_enable;
      uint64_t pre_mp_output_start_address; 
      uint32_t pre_mp_output_address_increment;
      uint64_t output_start_address;
      uint32_t output_address_increment;


      printf("Reading Layer %d : %s\n",i, layer[i].conv);

      n = read_xcaffe_file((char *) model_filename, layer[i].conv, layer[i].scale, layer[i].bn, layer[i].bias, 32767.0, layer[i].size,layer[i].mask,layer[i].mask,layer[i].features,layer[i].skip, pweight_mem);
      if (n<1)
	{
	  printf("Fatal Error: Failed to read weights from Model File\n");
	  goto done;
	}
     
      // Special case for layer 20 
      if ((i==26) || (i==27))
	{
	  concat_feature_start_address = WORKING_MEM_OFFSET + layer_ip_startoffset[19]; 
	  concat_feature_count1 = 128; 
	  concat_feature_count2 = 256; 
	  concat_feature_rescale_enable = 1;
	}
      else
	{
	  concat_feature_start_address = 0; 
	  concat_feature_count1 = 0; 
	  concat_feature_count2 = 0; 
	  concat_feature_rescale_enable = 0;
	}

      // Special case for layer 8
      if ((i==4) || (i==5))
	{
	  pre_mp_output_start_address = WORKING_MEM_OFFSET + layer_ip_startoffset[19] + ((i==4)? 0 : 128);
	  pre_mp_output_address_increment =256;
	}
      else
	{
	  pre_mp_output_start_address = 0;
	  pre_mp_output_address_increment =0;
	}



      if (i<max_layer-1)
	{
	  if (run_one_layer)
	    next_iword_enable = 0;
	  else
	    next_iword_enable = 1;
	  next_iword_offset = iword_offset+128; // +128 bytes
	}
      else
	{
	  next_iword_enable =0;
	  next_iword_offset =0;
	}

      if (layer[i].op_seq<2)
	{
	  // Standard case, layer has =< 128 neurons
	  output_start_address = WORKING_MEM_OFFSET + layer_ip_startoffset[layer[i].op];
	  output_address_increment = 0;
	}
      else
	{
	  // Handle cases where layer is split into multiple sequential runs	 	  
	  // Based on number of neurons and op_seq
	  output_start_address = WORKING_MEM_OFFSET + layer_ip_startoffset[layer[i].op]+layer[i].skip*layer[i].size/128;
	  output_address_increment = 128*layer[i].op_seq;
	}

      printf("Creating Layer %d : Instruction word at %8.8x =>  %8.8p\n",i, iword_offset, piword_mem);
      printf("Weights at %8.8x\n", weight_offset);
      printf("Input Features at %8.8x\n", (WORKING_MEM_OFFSET + layer_ip_startoffset[layer[i].ip]));
      if (concat_feature_start_address) printf("and at %8.8x\n", concat_feature_start_address);
      printf("Output Data at %8.8x\n", output_start_address);
      if (pre_mp_output_start_address) printf("and at %8.8x\n", pre_mp_output_start_address);
      
      create_dpu_iword(
		       layer[i].relu,
		       (layer[i].mask==3),
		       layer[i].maxp,
		       layer[i].stride2, 
		       layer[i].fwidth,
		       layer[i].features,
		       (layer[i].stride2 ? layer[i].fwidth/2 : layer[i].fwidth),
		       layer[i].size, 
		       layer[i].size,
		       layer[i].throttle,
		       (uint64_t) weight_offset,
		       (WORKING_MEM_OFFSET + layer_ip_startoffset[layer[i].ip]),
		       output_start_address,
		       output_address_increment, 
		       pre_mp_output_start_address, 
		       pre_mp_output_address_increment, 
		       concat_feature_start_address, 
		       concat_feature_count1, 
		       concat_feature_count2, 
		       concat_feature_rescale_enable, 
		       (uint64_t) next_iword_offset, 
		       next_iword_enable, 
		       piword_mem);
     
      
      piword_mem +=32;  // +32 * 4 bytes
      iword_offset = next_iword_offset;
      pweight_mem +=n;
      weight_offset +=2*n;

    }


  // Load Input File to "WORKING_MEM_OFFSET"

  fid = fopen(input_filename,"r");
  if (fid==NULL)
    {
      printf("Could not open input file %s\n",input_filename); 
      goto done;
    }
  for (i=0;i<3*416*416;i++)
    {
      int data;
      char d;
      fscanf(fid,"%d\n",&data);
      
      d= (char) (data & 0xFF);

      membuf[i+WORKING_MEM_OFFSET]=d; 
      
    }
  fclose(fid);
  

  // Open the Device - only supports device 0
  // A Device is logically a parent of Windows, DMA engines etc.
  status = ADXDMA_Open(deviceIndex, FALSE, &hDevice);
  if (ADXDMA_SUCCESS != status) {
    printf("Failed to open ADXDMA device with index %u: %s",
	   (unsigned long)0, ADXDMA_GetStatusString(status, TRUE));
    goto done;
  }

  // Open a DMA engine to write to the memory
  status = ADXDMA_OpenDMAEngine(hDevice, 0 /* ignored */, FALSE, TRUE, 0, &hDMAEngine);
  if (ADXDMA_SUCCESS != status) {
    printf("Failed to open ADXDMA Device %u %s%u: %s",
	   deviceIndex, "H2C", dmaEngineIndex, ADXDMA_GetStatusString(status, TRUE));
    goto done;
  }
  dmaTransferSize=20*1024*1024;

  status = ADXDMA_WriteDMA(hDMAEngine, 0, 0, membuf, dmaTransferSize, NULL);
  if (ADXDMA_SUCCESS != status) {
    printf("Failed to perform DMA transfer of 0x%X B: %s",
	   dmaTransferSize, ADXDMA_GetStatusString(status, TRUE));
    goto done;
  }
  
  status = ADXDMA_CloseDMAEngine(hDMAEngine);
  if (ADXDMA_SUCCESS != status) {
    printf("Failed to close ADXDMA Device %u %s%u: %s",
	   deviceIndex, "H2C", dmaEngineIndex, ADXDMA_GetStatusString(status, TRUE));
    goto done;
  }

  



  // Open the AXI Lite Window 
  status = ADXDMA_OpenWindow(hDevice, 0 /* ignored */, FALSE, liteWindowIndex, &hWindow);
  if (ADXDMA_SUCCESS != status) {
    printf(
      "Failed to open ADXDMA Device %u Window %u: %s",
      deviceIndex, liteWindowIndex, ADXDMA_GetStatusString(status, TRUE));
    goto done;
  }
  
 
  // Core run DPU loop
  if (1){
    uint32_t data, run_state;
    int i;
    int loop_count =0;

    if (run_one_layer)
      {
	// Run one layer at a time
	for (i=0;i<max_layer;i++)
	  {
	    printf("Running layer %d : %s - Neurons %d to %d\n",i,layer[i].conv,layer[i].skip, layer[i].skip +layer[i].size-1);
	    data = 0;
	    // Write 0 to upper 32 bits of start address
	    ADXDMA_WriteWindow(hWindow,0,4,4,4,&data,0);
	    // Write 0 to lower 32 bits of start address : starts DPU
	    data = i*128;
	    ADXDMA_WriteWindow(hWindow,0,4,0,4,&data,0);
	    run_state =1;
	    while (run_state) {
	      ADXDMA_ReadWindow(hWindow,0,4,8,4,&data,0);
	      printf("%8.8x ",data);      
	      ADXDMA_ReadWindow(hWindow,0,4,12,4,&data,0);
	      printf("%8.8x ",data);
	      if ((data & 0xF0000) == 0)
		run_state = 0;
	      if ((data & 0xF0000) == 0xF0000)
		{
		  run_state = 0;
		  printf("DPU State Machine In Error : clearing and exiting\n");
		  ADXDMA_WriteWindow(hWindow,0,4,12,4,&data,0);
		  break;
		}
	      ADXDMA_ReadWindow(hWindow,0,4,16,4,&data,0);
	      printf("%8.8x ",data);      
	      ADXDMA_ReadWindow(hWindow,0,4,20,4,&data,0);
	      printf("%8.8x\n",data);
	      usleep(250);
	      loop_count++;
	      if (loop_count>4000)
		break;

	    }
	    ADXDMA_ReadWindow(hWindow,0,4,16,4,&data,0);
	    printf("DPU Run Time %d cycles : %dms\n",data,data*8/1000000);
	    ADXDMA_ReadWindow(hWindow,0,4,20,4,&data,0);
	    printf("DPU Active Time %d cycles : %dms\n",data,data*8/1000000);
	    
	  }
	

      }
    else
      {
	// Run the layers as a linked list
	
	data = 0;
	// Write 0 to upper 32 bits of start address
	ADXDMA_WriteWindow(hWindow,0,4,4,4,&data,0);
	// Write 0 to lower 32 bits of start address : starts DPU
   
     
	ADXDMA_WriteWindow(hWindow,0,4,0,4,&data,0);
	run_state =1;
	while (run_state) {
	  ADXDMA_ReadWindow(hWindow,0,4,8,4,&data,0);
	  printf("%8.8x ",data);      
	  ADXDMA_ReadWindow(hWindow,0,4,12,4,&data,0);
	  printf("%8.8x ",data);
	  if ((data & 0xF0000) == 0)
	    run_state = 0;
	  if ((data & 0xF0000) == 0xF0000)
	    {
	      run_state = 0;
	      printf("DPU State Machine In Error : clearing and exiting\n");
	      ADXDMA_WriteWindow(hWindow,0,4,12,4,&data,0);
	      break;
	    }
	  ADXDMA_ReadWindow(hWindow,0,4,16,4,&data,0);
	  printf("%8.8x ",data);      
	  ADXDMA_ReadWindow(hWindow,0,4,20,4,&data,0);
	  printf("%8.8x\n",data);
	  usleep(250);
	  loop_count++;
	  if (loop_count>4000)
	    break;

	}
	ADXDMA_ReadWindow(hWindow,0,4,16,4,&data,0);
	printf("DPU Run Time %d cycles : %dms\n",data,data*8/1000000);
	ADXDMA_ReadWindow(hWindow,0,4,20,4,&data,0);
	printf("DPU Active Time %d cycles : %dms\n",data,data*8/1000000);
      }
  }

  status = ADXDMA_CloseWindow(hWindow);
  if (ADXDMA_SUCCESS != status) {
    printf(
      "Failed to close ADXDMA Device %u Window %u: %s",
      deviceIndex, liteWindowIndex, ADXDMA_GetStatusString(status, TRUE));
    goto done;
  }

  // Open a DMA engine to read back the memory
  status = ADXDMA_OpenDMAEngine(hDevice, 0 /* ignored */, FALSE, FALSE, 0, &hDMAEngine);
  if (ADXDMA_SUCCESS != status) {
    printf("Failed to open ADXDMA Device %u %s%u: %s",
	   deviceIndex, "C2H", dmaEngineIndex, ADXDMA_GetStatusString(status, TRUE));
    goto done;
  }
  
  // Read back layer 14 output
  status = ADXDMA_ReadDMA(hDMAEngine, 0, WORKING_MEM_OFFSET+layer_ip_startoffset[15], &membuf[WORKING_MEM_OFFSET+layer_ip_startoffset[15]],13*13*45 , NULL);
  if (ADXDMA_SUCCESS != status) {
    printf("Failed to perform DMA transfer of 0x%X B: %s",
	   13*13*45, ADXDMA_GetStatusString(status, TRUE));
    goto done;
  }

  // Read back layer 21 output
  status = ADXDMA_ReadDMA(hDMAEngine, 0, WORKING_MEM_OFFSET+layer_ip_startoffset[22], &membuf[WORKING_MEM_OFFSET+layer_ip_startoffset[22]], 26*26*45 , NULL);
  if (ADXDMA_SUCCESS != status) {
    printf("Failed to perform DMA transfer of 0x%X B: %s",
	   26*26*45, ADXDMA_GetStatusString(status, TRUE));
    goto done;
  }
  
  status = ADXDMA_CloseDMAEngine(hDMAEngine);
  if (ADXDMA_SUCCESS != status) {
    printf("Failed to close ADXDMA Device %u %s%u: %s",
	   deviceIndex, "C2H", dmaEngineIndex, ADXDMA_GetStatusString(status, TRUE));
    goto done;
  }


  // Write out layer 14 output

  fid = fopen("output14.txt","w");
  if (fid==NULL)
    {
      printf("Could not open output file output14.txt\n"); 
      goto done;
    }
  for (i=0;i<13*13*45;i++)
    fprintf(fid,"%d\n",membuf[WORKING_MEM_OFFSET+layer_ip_startoffset[15]+i]);
   
  fclose(fid);

  // Write out layer 21 output

  fid = fopen("output21.txt","w");
  if (fid==NULL)
    {
      printf("Could not open output file output21.txt\n"); 
      goto done;
    }
  for (i=0;i<26*26*45;i++)
    fprintf(fid,"%d\n",membuf[WORKING_MEM_OFFSET+layer_ip_startoffset[22]+i]);
  fclose(fid);



 done:

  if (ADXDMA_NULL_HDEVICE != hDevice) {
    status = ADXDMA_Close(hDevice);
    hDevice = ADXDMA_NULL_HDEVICE;
  }

  exit(0);

}
