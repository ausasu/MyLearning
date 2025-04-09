using UnityEngine;

public class CameraInfomation : MonoBehaviour
{
    [SerializeField]
    RenderTexture rt;

    [SerializeField]
    Transform target;
    // Start is called before the first frame update
    void Start()
    {
        Shader.SetGlobalTexture("_GlobalEffectRT", rt); //传render texture
        Shader.SetGlobalFloat("_OrthographicCamSize", GetComponent<Camera>().orthographicSize); //传正交相机的size值
    }

    // Update is called once per frame
    void Update()
    {
        //相机更随物体
        transform.position = new Vector3(target.transform.position.x, transform.position.y, target.transform.position.z);
        Shader.SetGlobalVector("_Position", transform.position);
    }
}
