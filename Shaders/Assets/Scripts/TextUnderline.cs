using UnityEngine;

public class TextUnderline : MonoBehaviour
{
    [SerializeField] private UnderlineTextMeshPro _underline;
    
    private void Update()
    {
        if (Input.GetKeyDown(KeyCode.Q)) 
            _underline.Play();
    }
}
