using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class Rotate : MonoBehaviour
{
    public float Speed = 10;

    // Update is called once per frame
    void Update()
    {
        transform.Rotate(Speed * Vector3.up * Time.deltaTime,Space.Self);
    }
}
