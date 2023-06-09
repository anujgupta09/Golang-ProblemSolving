/*
13. [Flipping an Image]
(https://leetcode.com/problems/flipping-an-image/)
*/

package main

import "fmt"

func main() {
	image := [][]int{
		{1, 2, 3},
		{1, 0, 0},
		{0, 4, 5},
	}
	fmt.Println(flipAndInvertImage(image))
}

//////////// flipAndInvertImage ////////////////////////////////////

func flipAndInvertImage(image [][]int) [][]int {

	n := len(image)
	array := make([][]int, n)
	for i := 0; i < n; i++ {
		array[i] = make([]int, n) // intitalizing array inside array
		for j := 0; j < n; j++ {
			array[i][j] = image[i][(n-1)-j]
			fmt.Println("1: ", array)
			if array[i][j] == 0 {
				array[i][j] = 1
			} else if array[i][j] == 1 {
				array[i][j] = 0
			}
			fmt.Println("2: ", array)
		}
		for k := 0; k < n; k++ {

		}
	}
	return array

}
