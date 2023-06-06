/*
8. [How Many Numbers Are Smaller Than the Current Number]
(https://leetcode.com/problems/how-many-numbers-are-smaller-than-the-current-number/)
*/

package main

import "fmt"

func main() {
	var nums []int = []int{111, 22, 31, 4, 5}
	fmt.Println(smallerNumbersThanCurrent(nums))
}

///////////smallerNumbersThanCurrent//////////////////////

func smallerNumbersThanCurrent(nums []int) []int {

	n := len(nums)
	ans := make([]int, n)

	for i := 0; i < n; i++ {
		count := 0
		for j := 0; j < n; j++ {
			if nums[i] > nums[j] && j != i {
				count += 1
			}
		}
		ans[i] = count
	}
	return ans
}
