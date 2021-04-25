import { async, ComponentFixture, TestBed } from '@angular/core/testing';

import { DocGdscComponent } from './doc-gdsc.component';

describe('DocGdscComponent', () => {
  let component: DocGdscComponent;
  let fixture: ComponentFixture<DocGdscComponent>;

  beforeEach(async(() => {
    TestBed.configureTestingModule({
      declarations: [ DocGdscComponent ]
    })
    .compileComponents();
  }));

  beforeEach(() => {
    fixture = TestBed.createComponent(DocGdscComponent);
    component = fixture.componentInstance;
    fixture.detectChanges();
  });

  it('should create', () => {
    expect(component).toBeTruthy();
  });
});
