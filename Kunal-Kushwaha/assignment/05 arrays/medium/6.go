/*

6. [Find First and Last Position of Element in Sorted Array]
(https://leetcode.com/problems/find-first-and-last-position-of-element-in-sorted-array/)

Given an array of integers nums sorted in non-decreasing order,
find the starting and ending position of a given target value.

If target is not found in the array, return [-1, -1].

You must write an algorithm with O(log n) runtime complexity.

*/

package main

import "fmt"

func main() {
	var nums []int = []int{1, 2, 3, 3, 3, 3, 3, 3, 3, 3, 4, 5, 6}
	var target int = 3
	fmt.Println(searchRange(nums, target))
}

func searchRange(nums []int, target int) []int {
	var sP, eP = -1, -1

	for i := 0; i < len(nums); i++ {
		if nums[i] == target {
			if sP < 0 {
				sP = i
			}
		}
		if nums[len(nums)-1-i] == target {
			if eP < 0 {
				eP = len(nums) - 1 - i
			}
		}
	}
	return []int{sP, eP}
}

// awesome solution found in solutions "hctapgt"
// func searchRange(nums []int, target int) []int {

//     var sp , ep = -1,-1
//     for i:=0;i<len(nums);i++{
//         if nums[i]==target{
//             if sp == -1{
//                 sp = i
//             }
//             ep = i
//         }
//     }
//     return []int{sp,ep}
// }
