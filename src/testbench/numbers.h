function integer util_test_numbers(input integer idx);
	integer nums[0:24];
	begin
		nums[0] = -9841;
		nums[1] = -9840;
		nums[2] = -6560;
		nums[3] = -10;
		nums[4] = -9;
		nums[5] = -8;
		nums[6] = -6;
		nums[7] = -5;
		nums[8] = -4;
		nums[9] = -3;
		nums[10] = -2;
		nums[11] = -1;
		nums[12] = 0;
		nums[13] = 1;
		nums[14] = 2;
		nums[15] = 3;
		nums[16] = 4;
		nums[17] = 5;
		nums[18] = 6;
		nums[19] = 8;
		nums[20] = 9;
		nums[21] = 10;
		nums[22] = 6560;
		nums[23] = 9840;
		nums[24] = 9841;
		util_test_numbers = nums[idx];
	end
endfunction
