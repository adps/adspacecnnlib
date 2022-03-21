#include <stdio.h>
#include <stdint.h>
#include <string.h>

#define RELU_BIT (1<<0)
#define CONV3X3_BIT (1<<1)
#define USE_MXP_BIT (1<<2)
#define STRIDE2_BIT (1<<3)

// Pack DPU configuration parameters into memory structure for DPU to read from RAM

int create_dpu_iword(int relu,int conv3x3,int use_maxpool,int stride2, int feature_image_width, int number_of_features, int mp_feature_image_width, int mp_number_of_features, int number_of_active_neurons, int throttle_rate, uint64_t weight_start_address, uint64_t features_start_address, uint64_t output_start_address, uint32_t output_address_increment, uint64_t pre_mp_output_start_address, uint32_t pre_mp_output_address_increment, uint64_t concat_feature_start_address, int concat_feature_count1, int concat_feature_count2, int concat_feature_rescale_enable, uint64_t next_iword_addr, int next_iword_enable, uint32_t *dpu_iword)
{

  uint32_t tmp;
  uint64_t tmp64;
  int op_width;
  int i;
  for (i=0;i<32;i++)
    dpu_iword[i] =0;

  tmp =0;
  tmp |= (relu ? RELU_BIT : 0x0);
  tmp |= (conv3x3 ? CONV3X3_BIT : 0x0);
  tmp |= (use_maxpool ? USE_MXP_BIT : 0x0);
  tmp |= (stride2 ? STRIDE2_BIT : 0x0);
  tmp |= feature_image_width << 16; 
  dpu_iword[0] = tmp;
  
  dpu_iword[1] = number_of_features | (mp_feature_image_width <<16);
  dpu_iword[2] = mp_number_of_features | (number_of_active_neurons <<16);
  dpu_iword[3] = throttle_rate;
  
  // WDM Command read weights
  tmp = 2 * (conv3x3 ? 9 : 1) * (number_of_features+1) * number_of_active_neurons;
  dpu_iword[4] = 0x40800000 | tmp;
  tmp64 = weight_start_address & 0x00000000FFFFFFFF;
  dpu_iword[5] = (uint32_t) tmp64;
  tmp64 = (weight_start_address & 0xFFFFFFFF00000000) >> 32;
  dpu_iword[6] = (uint32_t) tmp64;
  dpu_iword[7] = 0;
  
  // IDM Command read features
  if (concat_feature_count1)
    tmp = feature_image_width * feature_image_width * concat_feature_count1;
  else
    tmp = feature_image_width * feature_image_width * number_of_features;
  dpu_iword[8] = 0x40800000 | tmp;
  tmp64 = features_start_address & 0x00000000FFFFFFFF;
  dpu_iword[9] = (uint32_t) tmp64;
  tmp64 = (features_start_address & 0xFFFFFFFF00000000) >> 32;
  dpu_iword[10] = (uint32_t) tmp64;
  dpu_iword[11] = 0;

  // ODM Command write features
  if (use_maxpool) {
    if (stride2)
      op_width = feature_image_width /4;
    else
      op_width = feature_image_width /2;
  } else {
    if (stride2)
      op_width = feature_image_width /2;
    else
      op_width = feature_image_width;
  }
  if (output_address_increment == 0) {

    tmp = op_width * op_width * number_of_active_neurons;
    dpu_iword[12] = 0x00800000 | tmp;
    tmp64 = output_start_address & 0x00000000FFFFFFFF;
    dpu_iword[13] = (uint32_t) tmp64;
    tmp64 = (output_start_address & 0xFFFFFFFF00000000) >> 32;
    dpu_iword[14] = (uint32_t) tmp64;
    dpu_iword[15] = 0;
    dpu_iword[26] = 0;
  } else {
    tmp = op_width * op_width -1;
    dpu_iword[12] = 0x00800000 | number_of_active_neurons;
    tmp64 = output_start_address & 0x00000000FFFFFFFF;
    dpu_iword[13] = (uint32_t) tmp64;
    tmp64 = (output_start_address & 0xFFFFFFFF00000000) >> 32;
    dpu_iword[14] = (uint32_t) tmp64;
    dpu_iword[15] = tmp << 8 ;
    dpu_iword[26] = output_address_increment;
  }
  
  tmp64 = next_iword_addr & 0x00000000FFFFFFFF;
  dpu_iword[16] = (uint32_t) tmp64;
  tmp64 = (next_iword_addr & 0xFFFFFFFF00000000) >> 32;
  dpu_iword[17] = (uint32_t) tmp64;
  dpu_iword[18] = next_iword_enable;
  dpu_iword[19] = 0;
  
  // IDM2 Command - read second memory area for inline ConCat
  // IDM Command read features
  if (concat_feature_start_address != 0)
    {
      if (concat_feature_rescale_enable)
	tmp = feature_image_width * feature_image_width * concat_feature_count2 /4;
      else
	tmp = feature_image_width * feature_image_width * concat_feature_count2;
      dpu_iword[20] = 0x40800000 | tmp;
      tmp64 = concat_feature_start_address & 0x00000000FFFFFFFF;
      dpu_iword[21] = (uint32_t) tmp64;
      tmp64 = (concat_feature_start_address & 0xFFFFFFFF00000000) >> 32;
      dpu_iword[22] = (uint32_t) tmp64;
      dpu_iword[23] = 0;
  
      dpu_iword[25] = ( (concat_feature_count2-1) << 16 ) | (concat_feature_count1-1);
  
      // Enable 2x Rescale
      dpu_iword[24] = concat_feature_rescale_enable;
    }
  // ODM2 Command write features
 
  if (stride2)
    op_width = feature_image_width /2;
  else
    op_width = feature_image_width;
  
  if (pre_mp_output_start_address != 0) {
  if (pre_mp_output_address_increment == 0) {

    tmp = op_width * op_width * number_of_active_neurons;
    dpu_iword[28] = 0x00800000 | tmp;
    tmp64 = pre_mp_output_start_address & 0x00000000FFFFFFFF;
    dpu_iword[29] = (uint32_t) tmp64;
    tmp64 = (pre_mp_output_start_address & 0xFFFFFFFF00000000) >> 32;
    dpu_iword[30] = (uint32_t) tmp64;
    dpu_iword[31] = 0;
    dpu_iword[27] = 0;
  } else {
    tmp = op_width * op_width -1;
    dpu_iword[28] = 0x00800000 | number_of_active_neurons;
    tmp64 = pre_mp_output_start_address & 0x00000000FFFFFFFF;
    dpu_iword[29] = (uint32_t) tmp64;
    tmp64 = (pre_mp_output_start_address & 0xFFFFFFFF00000000) >> 32;
    dpu_iword[30] = (uint32_t) tmp64;
    dpu_iword[31] = tmp << 8 ;
    dpu_iword[27] = output_address_increment;
  }
  }

};

