import { async, ComponentFixture, TestBed } from '@angular/core/testing';

import { DocGsvaRppaComponent } from './doc-gsva-rppa.component';

describe('DocGsvaRppaComponent', () => {
  let component: DocGsvaRppaComponent;
  let fixture: ComponentFixture<DocGsvaRppaComponent>;

  beforeEach(async(() => {
    TestBed.configureTestingModule({
      declarations: [ DocGsvaRppaComponent ]
    })
    .compileComponents();
  }));

  beforeEach(() => {
    fixture = TestBed.createComponent(DocGsvaRppaComponent);
    component = fixture.componentInstance;
    fixture.detectChanges();
  });

  it('should create', () => {
    expect(component).toBeTruthy();
  });
});
