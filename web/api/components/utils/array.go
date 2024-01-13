package utils

func ArrayContains[T comparable](container []T, value T) bool {
	for _, v := range container {
		if v == value {
			return true
		}
	}
	return false
}
