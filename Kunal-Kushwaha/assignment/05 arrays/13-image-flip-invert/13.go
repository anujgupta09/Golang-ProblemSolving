/*
13. [Flipping an Image]
(https://leetcode.com/problems/flipping-an-image/)
*/

package main

import "fmt"

func main() {
	image := [][]int{
		{0, 0, 0, 00, 0, 000, 1, 2, 3, 4, 5, 6, 222},
		{1, 0, 0, 2, 2, 2, 111, 45, 0, 0, 0, 0, 0, 1, 1, 1},
		{0, 4, 5, 0, 0, 0, 0, 0, 0, 00, 0, 0, 0, 0, 0, 0, 00, 0, 0, 0, 0, 0},
	}
	fmt.Println(": \n :")
	fmt.Println(flipAndInvertImage(image))
}

//////////// flipAndInvertImage ////////////////////////////////////

func flipAndInvertImage(image [][]int) [][]int {

	nOf1stD := len(image) // length of 1st dimension of array
	fmt.Println(image)
	array := make([][]int, nOf1stD)
	for i := 0; i < nOf1stD; i++ {
		nOf2ndD := len(image[i]) // length of 2nd dimension of array
		fmt.Println(nOf1stD, " : ", nOf2ndD)
		array[i] = make([]int, nOf2ndD) // intitalizing array inside array
		for j := 0; j < nOf2ndD; j++ {
			array[i][j] = image[i][(nOf2ndD-1)-j] //logic for horizontal flip
			fmt.Println("1: ", array)
			if array[i][j] == 0 { // logic for invert 0>1 1>0
				array[i][j] = 1
			} else if array[i][j] == 1 {
				array[i][j] = 0
			}
			fmt.Println("2: ", array)
		}
	}
	return array

}
