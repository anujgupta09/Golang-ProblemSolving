/*
4. [Richest Customer Wealth](https://leetcode.com/problems/richest-customer-wealth/)
*/

package main

import "fmt"

func main() {
	var accounts [][]int = [][]int{{2, 2, 2}, {4, 4, 4}, {5, 5, 5, 5, 5, 5, 5}, {3, 3}}
	fmt.Println(maximumWealth(accounts))
}

func maximumWealth(accounts [][]int) int {

	var wealth = 0
	var wealthiest int

	for i := 0; i < len(accounts); i++ {
		var currentW = 0

		for j := 0; j < len(accounts[i]); j++ {
			currentW += accounts[i][j]
		}
		if currentW > wealth {
			wealth = currentW
			wealthiest = i
			fmt.Println("wealthiest : ", wealthiest)
		}
	}
	return wealth
}
