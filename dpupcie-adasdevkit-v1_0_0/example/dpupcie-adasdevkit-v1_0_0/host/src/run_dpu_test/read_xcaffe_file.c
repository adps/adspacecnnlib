
#include <stdio.h>
#include <stdint.h>
#include <string.h>

#define MAXLINE 128

#define DBG_PRINTF //printf


int read_xcaffe_file(char *xcaffe_filename, char *layer_name, char *scale_layer_name, char *bn_layer_name, int has_bias, double weight_scaling, int layer_size,int input_mask_height, int input_mask_width, int input_no_features, int neuron_skip, int16_t *mem)
{
  FILE *fid;
  
  char linebuf[MAXLINE];
  char *linebuf_ptr = &linebuf[0];
  int found_line_of_interest = 0;
  size_t linesize = MAXLINE;
  
  char *found;
  int  weight_index;
  int skip;
  int read_weights;
  int n,j,k,i;
  
  float p;
  float weight_array[256*1024*4];
  float bias_array[4096*4];

  fid=fopen(xcaffe_filename,"r");
  if (fid!=NULL)
    {
      // Find start of Layer
      while ((!feof(fid)) && (!found_line_of_interest))
	{
	  if (getline(&linebuf_ptr,&linesize,fid)==-1) {goto close_file;};
	  found = strstr(linebuf, "name:");	  
	  if (found != NULL) {	 
	    DBG_PRINTF("Found a name line: %s\n",linebuf);
	    found = strstr(linebuf, layer_name);
	    if (found !=NULL)
	      found_line_of_interest = 1;
	  }
	}
      found_line_of_interest = 0;

      // First Blob contains raw weights
      while ((!feof(fid)) && (!found_line_of_interest))
	{
	  if (getline(&linebuf_ptr,&linesize,fid)==-1) {goto close_file;};
	  found = strstr(linebuf, "blobs");
	  if (found != NULL) {	 
	    DBG_PRINTF("Found weights blob start line: %s\n",linebuf);
	    found_line_of_interest = 1;
	  }
	}
      found_line_of_interest = 0;

      weight_index =0;
      skip =0;
      read_weights =0;

      
      // Skip over data for partially implementing layers larger than DPU size
      while (skip < (neuron_skip*input_mask_height*input_mask_width*input_no_features))
	{
	  skip++;
	  if (getline(&linebuf_ptr,&linesize,fid)==-1) {goto close_file;};
	}
      for (n=1;n<=layer_size;n++)
	for (j=1;j<=input_mask_height;j++)
	  for(k=1;k<=input_mask_width;k++)
	    for(i=1;i<=input_no_features;i++)
	      {
		if (getline(&linebuf_ptr,&linesize,fid)==-1) {goto close_file;};
		found=strstr(linebuf,"data:");
		if (found !=NULL) {
		  sscanf(found+6,"%f",&p);
		  weight_array[weight_index]=p;
		  DBG_PRINTF("%d : %f : %d\n",weight_index,p, (int) p);
		  if ((n==layer_size)&&(j==input_mask_height)&&(k==input_mask_width)&&(i==input_no_features))
		    read_weights=1;
		  weight_index++;
		}
		else {
		  DBG_PRINTF("Incorrect Layer Size Specified\n");
		  goto close_file;
		}		  
	      }
      
      
      if (has_bias)
	{
	  // Next blob contains bias, if there is a bias
	  while ((!feof(fid)) && (!found_line_of_interest))
	    {
	      if (getline(&linebuf_ptr,&linesize,fid)==-1) {goto close_file;};
	      found = strstr(linebuf, "blobs");
	      if (found != NULL) {	 
		DBG_PRINTF("Found bias blob start line: %s\n",linebuf);
		found_line_of_interest = 1;
	      }
	    }
	  found_line_of_interest = 0;
	  weight_index =0;
	  read_weights=0;
	  skip =0;
        
	  // Skip over data for partially implementing layers larger than DPU size
	  while (skip < (neuron_skip))
	    {
	      skip++;
	      if (getline(&linebuf_ptr,&linesize,fid)==-1) {goto close_file;};
	    }
	  for (n=1;n<=layer_size;n++)
	      {
		if (getline(&linebuf_ptr,&linesize,fid)==-1) {goto close_file;};
		
		if (found !=NULL) {
		  found=strstr(linebuf,"data:");
		  sscanf(found+6,"%f",&p);
		  bias_array[weight_index]=p;
		  DBG_PRINTF("%d : %f : %d\n",weight_index,p, (int) p);
		  if ((n==layer_size))
		    read_weights=1;
		  weight_index++;
		}
		else {
		  DBG_PRINTF("Incorrect Layer Size Specified\n");
		  goto close_file;
		}		  
	      }
	}

	

      //Find the BN Layer name, to modify the weights (to scale output by
      //that factor) and also to get the bias
      if (bn_layer_name != NULL)
	if (bn_layer_name[0] != '\0') {
	  while ((!feof(fid)) && (!found_line_of_interest))
	    {
	      if (getline(&linebuf_ptr,&linesize,fid)==-1) {goto close_file;};
	      found = strstr(linebuf, "name:");
	      
	      if (found != NULL) {
		DBG_PRINTF("Found a name line: %s\n",linebuf);
		found = strstr(linebuf, bn_layer_name);
		if (found !=NULL)
		  found_line_of_interest = 1;
	      }
	    }

	  if (found_line_of_interest) {
	    found_line_of_interest =0;
	    // Found BN Layer, scale weights by 1st blob,
	    // Bias is 2nd blob
	    while ((!feof(fid)) && (!found_line_of_interest))
	      {
		if (getline(&linebuf_ptr,&linesize,fid)==-1) {goto close_file;};
		found = strstr(linebuf, "blobs");
		if (found != NULL) {	 
		  DBG_PRINTF("Found Scale BN blob start line: %s\n",linebuf);
		  found_line_of_interest = 1;
		}
	      }
	    found_line_of_interest = 0;

	    weight_index =0;
	    skip =0;
	    read_weights =0;

      
	    // Skip over data for partially implementing layers larger than DPU size
	    while (skip < (neuron_skip))
	      {
		skip++;
		if (getline(&linebuf_ptr,&linesize,fid)==-1) {goto close_file;};
	      }
	    for (n=1;n<=layer_size;n++) {
	      if (getline(&linebuf_ptr,&linesize,fid)==-1) {goto close_file;};
	      found=strstr(linebuf,"data:");
	      if (found !=NULL) {
		sscanf(found+6,"%f",&p);
	      } else {
		  DBG_PRINTF("Incorrect Layer Size Specified\n");
		  goto close_file;
	      }	
	      DBG_PRINTF("Scaling weights by %f\n",p);
	      for (j=1;j<=input_mask_height;j++)
		for(k=1;k<=input_mask_width;k++)
		  for(i=1;i<=input_no_features;i++)
		    {
		      
		      if (found !=NULL) {
		
			weight_array[weight_index]=p*weight_array[weight_index];
			DBG_PRINTF("%d : %f : %d\n",weight_index,weight_array[weight_index], (int) weight_array[weight_index]);
			if ((n==layer_size)&&(j==input_mask_height)&&(k==input_mask_width)&&(i==input_no_features))
			  read_weights=1;
			weight_index++;
		
		      }		  
		    }
	    }
	    
	    // Bias is 2nd blob
	    while ((!feof(fid)) && (!found_line_of_interest))
	      {
		if (getline(&linebuf_ptr,&linesize,fid)==-1) {goto close_file;};
		found = strstr(linebuf, "blobs");
		if (found != NULL) {	 
		  DBG_PRINTF("Found Bias BN blob start line: %s\n",linebuf);
		  found_line_of_interest = 1;
		}
	      }
	    found_line_of_interest = 0;

	    weight_index =0;
	    skip =0;
	    read_weights =0;

      
	    // Skip over data for partially implementing layers larger than DPU size
	    while (skip < (neuron_skip))
	      {
		skip++;
		if (getline(&linebuf_ptr,&linesize,fid)==-1) {goto close_file;};
	      }
	    for (n=1;n<=layer_size;n++)
	      {
		if (getline(&linebuf_ptr,&linesize,fid)==-1) {goto close_file;};
		found=strstr(linebuf,"data:");
		if (found !=NULL) {
		  sscanf(found+6,"%f",&p);
		  bias_array[weight_index]=p;
		  DBG_PRINTF("%d : %f : %d\n",weight_index,p, (int) p);
		  if ((n==layer_size))
		    read_weights=1;
		  weight_index++;
		}
		else {
		  DBG_PRINTF("Incorrect Layer Size Specified\n");
		  goto close_file;
		}		  
	      }
	    

	    found_line_of_interest = 0; 
	  }
	}


      
      //Find the Scale Layer name, to modify the weights (to scale output by
      //that factor) and also to scale the bias
      if (scale_layer_name != NULL)
	if (scale_layer_name[0] != '\0') {
	  while ((!feof(fid)) && (!found_line_of_interest))
	    {
	      if (getline(&linebuf_ptr,&linesize,fid)==-1) {goto close_file;};
	      found = strstr(linebuf, "name:");
	      
	      if (found != NULL) {
		DBG_PRINTF("Found a name line: %s\n",linebuf);
		found = strstr(linebuf, scale_layer_name);
		if (found !=NULL)
		  found_line_of_interest = 1;
	      }
	    }

	  if (found_line_of_interest) {
	    found_line_of_interest =0;
	    // Found BN Layer, scale weights by 1st blob,
	    // Bias is 2nd blob
	    while ((!feof(fid)) && (!found_line_of_interest))
	      {
		if (getline(&linebuf_ptr,&linesize,fid)==-1) {goto close_file;};
		found = strstr(linebuf, "blobs");
		if (found != NULL) {	 
		  DBG_PRINTF("Found BN blob start line: %s\n",linebuf);
		  found_line_of_interest = 1;
		}
	      }
	    found_line_of_interest = 0;

	    weight_index =0;
	    skip =0;
	    read_weights =0;

      
	    // Skip over data for partially implementing layers larger than DPU size
	    while (skip < (neuron_skip))
	      {
		skip++;
		if (getline(&linebuf_ptr,&linesize,fid)==-1) {goto close_file;};
	      }
	    for (n=1;n<=layer_size;n++) {
	      if (getline(&linebuf_ptr,&linesize,fid)==-1) {goto close_file;};
	      found=strstr(linebuf,"data:");
	      if (found !=NULL) {
		sscanf(found+6,"%f",&p);
	      } else {
		  DBG_PRINTF("Incorrect Layer Size Specfied\n");
		  goto close_file;
	      }
	      DBG_PRINTF("Scaling weights by %f\n",p);
	      for (j=1;j<=input_mask_height;j++)
		for(k=1;k<=input_mask_width;k++)
		  for(i=1;i<=input_no_features;i++)
		    {
		      
		      if (found !=NULL) {
		
			weight_array[weight_index]=p*weight_array[weight_index];
			DBG_PRINTF("%d : %f : %d\n",weight_index,weight_array[weight_index], (int) weight_array[weight_index]);
			if ((n==layer_size)&&(j==input_mask_height)&&(k==input_mask_width)&&(i==input_no_features))
			  read_weights=1;
			weight_index++;
		
		      }		  
		    }
	    }
	    
	    // Bias is 2nd blob
	    while ((!feof(fid)) && (!found_line_of_interest))
	      {
		if (getline(&linebuf_ptr,&linesize,fid)==-1) {goto close_file;};
		found = strstr(linebuf, "blobs");
		if (found != NULL) {	 
		  DBG_PRINTF("Found BN blob start line: %s\n",linebuf);
		  found_line_of_interest = 1;
		}
	      }
	    found_line_of_interest = 0;

	    weight_index =0;
	    skip =0;
	    read_weights =0;

      
	    // Skip over data for partially implementing layers larger than DPU size
	    while (skip < (neuron_skip))
	      {
		skip++;
		if (getline(&linebuf_ptr,&linesize,fid)==-1) {goto close_file;};
	      }
	    for (n=1;n<=layer_size;n++)
	      {
		if (getline(&linebuf_ptr,&linesize,fid)==-1) {goto close_file;};
		found=strstr(linebuf,"data:");
		if (found != NULL) {
		  sscanf(found+6,"%f",&p);
		  DBG_PRINTF("Shifting bias by %f\n",p);
		  bias_array[weight_index]=bias_array[weight_index]+p;
		  DBG_PRINTF("%d : %f : %d\n",weight_index,bias_array[weight_index], (int) bias_array[weight_index]);
		  if ((n==layer_size))
		    read_weights=1;
		  weight_index++;
		}
		else {
		  DBG_PRINTF("Incorrect Layer Size Specified\n");
		  goto close_file;
		}		  
	      }
	    

	    found_line_of_interest = 0; 
	  }

	


	}

       

    close_file:
      fclose(fid);


      if (read_weights)
	{
	  int16_t tmp;
	  int tmp_i;
	  float tmp_f;
	  int mem_index=0;
	  int weight_index=0;
	  for (n=1;n<=layer_size;n++) {
	    tmp_f = bias_array[n-1]*weight_scaling;
	    tmp_i = (int) tmp_f;
	    tmp = (int16_t) tmp_i;
	    mem[mem_index++] = tmp;
	    DBG_PRINTF("\nBias %d : Weights ",tmp); 
	    for (j=1;j<=input_mask_height;j++)
	      for(k=1;k<=input_mask_width;k++)
		for(i=1;i<=input_no_features;i++)
		  {
		    tmp_f = weight_array[weight_index++]*weight_scaling;
		    tmp_i = (int) tmp_f;
		    tmp = (int16_t) tmp_i;
		    mem[mem_index++] = tmp;
		    DBG_PRINTF("%d,",tmp);
		  }
	  }
	  DBG_PRINTF("\n");
	  return mem_index;
	}
      else
	return read_weights;
    }
  else
    return -1;
  
    }
 
/*

int main(int argc, char* argv[])
{
  
  int16_t mem[256*1024];
 
  read_xcaffe_file("../../../../../../onelayerdpu/data/dk_tiny-yolov3_416_416_5.txt", "layer8-conv", "layer8-scale", "layer8-bn", 0, 32767.0, 128,3,3,128,0, mem);

  exit(1);

}
*/
