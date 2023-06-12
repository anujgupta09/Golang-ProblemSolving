/*
14. [Cells with Odd Values in a Matrix]
(https://leetcode.com/problems/cells-with-odd-values-in-a-matrix/)
*/

package main

import "fmt"

func main() {
	m := 2
	n := 3
	indices := [][]int{
		{0, 1},
		{1, 1},
	}
	fmt.Println("oddCells function : ", oddCells(m, n, indices))
}

////////// oddCells ///////////////////////////////////////

func oddCells(m int, n int, indices [][]int) int {

	var n1 = len(indices)
	count := 0

	array := make([][]int, m)
	for i := 0; i < m; i++ {
		array[i] = make([]int, n)
		for j := 0; j < n; j++ {
			array[i][j] = 0
		}
	}
	fmt.Println("array    : ", array)

	for i := 0; i < n1; i++ {

		i1, i2 := indices[i][0], indices[i][1]

		fmt.Println("i1 : ", i1, "i2 : ", i2)

		for j := 0; j < len(array); j++ {
			fmt.Println("array j : ", array[j], "j : ", j)
			for k := 0; k < len(array[j]); k++ {
				// main logic
				if j == i1 {
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
	}
	for i := 0; i < len(array); i++ {
		for j := 0; j < len(array[i]); j++ {
			fmt.Println("array i j : ", array[i][j])
			if array[i][j]%2 == 1 {
				count += 1
			}
		}
	}
	fmt.Println(array)

	return count
}
