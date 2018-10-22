# motor_analyzer

Fork from opensource repo [RealtimePlotter](https://github.com/sebnil/RealtimePlotter) by sebnil. Many thanks :D   


## Installation
1. Install JAVA & processing first   

2. Copy the library folder 'controlP5' to your processing libraries directory  
default path should be `C:\Users\{user_name}\Documents\Processing\libraries`

## How to use?
1. Connect serial interface to COM first (your PC)
2. Open `motor_analyzer` sketch

### Key-binding
Clear encoder data 	: <kbd>c</kbd>  
Clear velocity data : <kbd>v</kbd>  
Clear pwm data 		:	<kbd>b</kbd>  
Stop/Resume data update : <kbd>  spacebar</kbd>  

### More...?

* Uart data format:  

|   Uart stream |     |          |     |           |     |           |     |     |     |      |       |
| ------------- | --- | -------- | --- | --------- | --- | --------- | --- | --- | --- | ---- | ----- |
| encoder count | ' ' | path_pos | ' ' | unit_velo | ' ' | path_velo | ' ' | pwm | ' ' |  pid | '\r'  |  



* If you have more than 1 COM connected, selsect your COM by changing:  
`int COM_NUM = 0;`

* All the data receive from UART will be saved as a text file, the default file name format is accroding to the day-time. You can change it :   
`String output_data_file_name = "motorData" + year() + "-" + month() + "-" + day() + "-" +
                      hour() + "_" + minute() + "_" + second();`

* You can change the y-axis iterval of each graph by textfield on left hand side. By default it will auto increase the max/min if new received data is larger/smaller than old max/min.

* You can change the num of data point (x-axis) :   
`final int enc_visible_data_range = 200;`   
`final int velo_visible_data_range = 200;`  
`final int pwm_visible_data_range = 100;`  