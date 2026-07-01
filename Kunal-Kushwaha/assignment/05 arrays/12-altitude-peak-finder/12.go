/*
12. [Find the Highest Altitude]
(https://leetcode.com/problems/find-the-highest-altitude/)
*/

package main

import "fmt"

func main() {
	gain := []int{-5, 1, 5, 0, -7}
	fmt.Println(largestAltitude(gain))
}

///////////// largestAltitude ///////////////////////////

func largestAltitude(gain []int) int {

	highestAltitude := 0
	currentAltitude := 0
	n := len(gain)

	for i := 0; i < n; i++ {
		currentAltitude += gain[i]
		if currentAltitude > highestAltitude {
			highestAltitude = currentAltitude
		}
	}

	return highestAltitude
}
