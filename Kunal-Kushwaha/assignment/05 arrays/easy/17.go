// 17. [Transpose Matrix]
// (https://leetcode.com/problems/transpose-matrix/)

package main

import "fmt"

func main() {
	var matrix = [][]int{
		{1, 2},
		{4, 5, 6},
		{7},
		{8, 9},
		{10, 11},
	}
	fmt.Println(transpose(matrix))
}
func transpose(matrix [][]int) [][]int {

	// transposeMatrix := matrix // this just make it another reference of matrix array hence change to one changes another too

	maxLenghtOfColumnToDecideRowOfTransposeMatrix := 0
	rowLengthMap := map[int]int{}

	// loop to decide rows in transpose matrix
	for rowIndex, _ := range matrix {

		if len(matrix[rowIndex]) > maxLenghtOfColumnToDecideRowOfTransposeMatrix {
			maxLenghtOfColumnToDecideRowOfTransposeMatrix = len(matrix[rowIndex])
		}
	}
	for i := 0; i < maxLenghtOfColumnToDecideRowOfTransposeMatrix; i++ {
		for rowIndex, _ := range matrix {
			count := 0
			var i int
			if matrix[rowIndex][i] <= 0 || matrix[rowIndex][i] >= 0 {
				count += 1
				continue
			}
			fmt.Println(rowLengthMap[i])
			rowLengthMap[i] = count
		}

	}

	fmt.Println("map : ", rowLengthMap)
	// var transposeMatrix [][]int = make([][]int, maxLenghtOfColumnToDecideRowOfTransposeMatrix) // intialize array with make
	return matrix
}
