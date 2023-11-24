using System.Collections;
using System.Collections.Generic;
using System.Linq;
using TMPro;
using UnityEngine;
using UnityEngine.UI;

public class UnderlineTextMeshPro : MonoBehaviour
{
    [SerializeField] private TextMeshProUGUI _text;
    [SerializeField] private string _underlineLinkTag;
    [SerializeField] private Image _templateUnderline;

    public float HeightOffset = 1;
    public float Velocity = 1;

    private Coroutine _coroutine;
    private List<GameObject> _underlines = new();
    
    public void Play()
    {
        Stop();
        _coroutine = StartCoroutine(UnderlinePlaying(Velocity));
    }

    public void Stop()
    {
        foreach (var underline in _underlines) 
            Destroy(underline);
        
        _underlines.Clear();

        if (_coroutine != null)
            StopCoroutine(_coroutine);
        _coroutine = null;
    }
    
    private IEnumerator UnderlinePlaying(float velocity)
    {
        var points = FindPoints(_text.textInfo, _text.textInfo.linkInfo, _underlineLinkTag);
        for (var i = 0; i < points.Length; i += 2) 
            yield return StartCoroutine(Underlining(points[i], points[i + 1], velocity));
    }

    private IEnumerator Underlining(Vector2 start, Vector2 end, float velocity)
    {
        var underline = Instantiate(_templateUnderline, _text.transform);
        _underlines.Add(underline.gameObject);
        underline.rectTransform.localPosition = start;
        var initialPoint = underline.rectTransform.localPosition - new Vector3(0, HeightOffset, 0);
        var line = end.x - start.x;
        var t = 0f;

        while (t < velocity * line / 100)
        {
            var width = Mathf.Lerp(0, line, t / (velocity * line / 100));
            underline.rectTransform.sizeDelta = new Vector2(width, underline.rectTransform.sizeDelta.y);
            underline.rectTransform.localPosition = initialPoint + Vector3.right * width / 2;
            t += Time.deltaTime;
            yield return null;
        }
    }

    private Vector3[] FindPoints(TMP_TextInfo textInfo, IEnumerable<TMP_LinkInfo> info, string underlineTag)
    {
        var result = new List<Vector3>();
        var previousRight = Vector3.zero;
        var isFirstLeftPoint = true;

        foreach (var linkInfo in info.Where(link => link.GetLinkID() == underlineTag))
        {
            var startIndex = linkInfo.linkTextfirstCharacterIndex;
            var endIndex = linkInfo.linkTextfirstCharacterIndex + linkInfo.linkTextLength;

            for (var i = startIndex; i < endIndex; i++)
            {
                var characterInfo = textInfo.characterInfo[i];
                var leftPoint = characterInfo.bottomLeft;
                var rightPoint = characterInfo.bottomRight;

                if (isFirstLeftPoint)
                {
                    result.Add(leftPoint);
                    isFirstLeftPoint = false;
                }
                
                if (!char.IsLetter(characterInfo.character))
                {
                    result.Add(previousRight);
                    isFirstLeftPoint = true;
                }

                if (i == endIndex - 1)
                {
                    result.Add(rightPoint);
                }

                previousRight = rightPoint;
            }
            
        }

        return result.ToArray();
    }
}