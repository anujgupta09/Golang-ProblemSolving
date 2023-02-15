/*
5. [Shuffle the Array](https://leetcode.com/problems/shuffle-the-array/)


Given the array nums consisting of 2n elements in the form [x1,x2,...,xn,y1,y2,...,yn].

Return the array in the form [x1,y1,x2,y2,...,xn,yn].

*/
//////////////////////////////////////////////////////////
package main

import "fmt"

///////////////////// main ///////////////////////////////
func main() {
	var nums []int = []int{1, 3, 5, 7, 9, 2, 4, 6, 8, 10}
	var n = len(nums) / 2
	fmt.Println(shuffle(nums, n))
}

/////////////////// shuffle //////////////////////////////

func shuffle(nums []int, n int) []int {

	array := make([]int, 2*n)
	var pos = 0

	for i := 0; i < n; i++ {
		array[pos], array[pos+1] = nums[i], nums[i+n]
		pos += 2
	}

	return array
}

/////////////////////////////////////////////////////////
