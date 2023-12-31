using System.Collections;
using UnityEngine;
using UnityEngine.UI;

public class SimplePlayer : MonoBehaviour
{
    private static readonly int IsDissolve = Shader.PropertyToID("_IsDissolve");
    private static readonly int Progress = Shader.PropertyToID("_Progress");
    
    [SerializeField] private Image _image;
    [SerializeField] private Sprite _a;
    [SerializeField] private Sprite _b;
    
    [SerializeField] private Material _material;

    private void Update()
    {
        if (Input.GetKeyDown(KeyCode.Q))
            Play();
    }

    private void Play()
    {
        StartCoroutine(Playing());
    }

    private IEnumerator Playing()
    {
        yield return ShowImage(_a);
        yield return new WaitForSeconds(3);
        yield return HideImage();
        yield return ShowImage(_b);
        yield return new WaitForSeconds(2);
        yield return HideImage();
    }

    private IEnumerator ShowImage(Sprite image)
    {
        var t = 0f;
        _material.SetFloat(IsDissolve, 0.0f);
        _image.sprite = image;
        while (t < 1)
        {
            t += Time.deltaTime;
            _material.SetFloat(Progress, t);
            yield return null;
        }
    }

    private IEnumerator HideImage()
    {
        _material.SetFloat(IsDissolve, 1.0f);
        var t = 0f;
        while (t < 1 / 2f)
        {
            t += Time.deltaTime;
            _material.SetFloat(Progress, (1/2f - t) * 2);
            yield return null;
        }
    }
}
