/*
14. [Cells with Odd Values in a Matrix]
(https://leetcode.com/problems/cells-with-odd-values-in-a-matrix/)
*/

package main

import "fmt"

func main() {
	m := 6
	n := 5
	indices := [][]int{
		{0, 1},
		{1, 1},
		{2, 3},
	}
	fmt.Println("oddCells function : ", oddCells(m, n, indices))
}

////////// oddCells ///////////////////////////////////////

func oddCells(m int, n int, indices [][]int) int {

	var lenOfIndice = len(indices) // taking len of indices array
	count := 0                     // intialize to 0

	// creating array >>>>>>>>>>

	array := make([][]int, m) // making empty array , size is rows i.e 'm' here
	for i := 0; i < m; i++ {  // loop to iterate in array and create cloumns using 'n'
		array[i] = make([]int, n) // size is n here
		for j := 0; j < n; j++ {
			array[i][j] = 0
		}
	}
	fmt.Println("array    : ", array)

	// creating array <<<<<<<<<<

	// iterrating over indices array and updating the main array as per conditions >>>

	for i := 0; i < lenOfIndice; i++ {

		i1, i2 := indices[i][0], indices[i][1] // fixed zero in indices[][0] means it will retrieve 0th positition in all elements of indices array which is again a array with 2 element [pos1,pos2] , similarly indices[][1] for 2nd position

		fmt.Println("---------------------------------------")
		fmt.Println("i1 : ", i1, "i2 : ", i2)
		fmt.Println("---------------------------------------")

		// we took the first indices and now incrementing based on that indices

		for j := 0; j < len(array); j++ { // iterate to row of array
			fmt.Println("array j : ", array[j], "j : ", j)
			for k := 0; k < len(array[j]); k++ { // iterate to column or row of array
				// main logic
				if j == i1 { // means row is = to i1
					array[j][k] += 1
					fmt.Println("array main logic : ", array)
				}
				if k == i2 {
					array[j][k] += 1
					fmt.Println("array main logic : ", array)
				}
				// main logic
			}
		}
		fmt.Println("============================================")
	}

	// iterating over indices array and updating the main array as per conditions <<<

	// updating count as we got the final updated array >>>

	for i := 0; i < len(array); i++ {
		for j := 0; j < len(array[i]); j++ {
			fmt.Println("array i j : ", array[i][j])
			if array[i][j]%2 == 1 { // to check odd no. or not
				count += 1
			}
		}
	}
	fmt.Println(array)
	// updating count as we got the final updated array >>>

	return count
}
