using UnityEngine;

[ExecuteInEditMode]
public class getL : MonoBehaviour
{
     public Material material;
    // Start is called before the first frame update
    void Start()
    {
        
    }

    // Update is called once per frame
    void Update()
    {
        material.SetVector("_Front", gameObject.transform.forward);
      
        material.SetVector("_LeftDir", -gameObject.transform.right);
    }
}
