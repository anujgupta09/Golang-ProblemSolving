/*
7. [Number of Good Pairs]
(https://leetcode.com/problems/number-of-good-pairs/)
*/

package main

import "fmt"

func main() {
	nums := []int{1, 2, 3, 1, 1, 3}
	fmt.Println(numIdenticalPairs(nums))
}

func numIdenticalPairs(nums []int) int {
	pairCount := 0
	n := len(nums)
	for i := 0; i < n; i++ {
		for j := 0; j < n; j++ {
			if nums[i] == nums[j] && i < j {
				fmt.Println(i, ",", j)
				pairCount += 1
			}
		}
	}
	return pairCount
}
