/*
6. [Kids With the Greatest Number of Candies](https://leetcode.com/problems/kids-with-the-greatest-number-of-candies/)
*/

package main

import "fmt"

func main() {
	var candies []int = []int{1, 2, 3, 4, 5}
	var extraCandies = 1
	resultArray := kidsWithCandies(candies, extraCandies)
	fmt.Println(resultArray)
}

func kidsWithCandies(candies []int, extraCandies int) []bool {
	var highestCandies = 0
	var result = make([]bool, len(candies))
	for _, candy := range candies {
		if candy > highestCandies {
			highestCandies = candy
		}
	}
	for indexNo, candy := range candies {
		if candy+extraCandies >= highestCandies {
			result[indexNo] = true
		} else {
			result[indexNo] = false
		}
	}
	return result
}
